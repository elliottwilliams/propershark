//
//  Connection.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MDWamp
import ReactiveCocoa
import Result

typealias WampArgs = [AnyObject]
typealias WampKwargs = [NSObject: AnyObject]
typealias EventProducer = SignalProducer<TopicEvent, ProperError>

// All connections conform to this protocol, which allows ConnectionMock to be injected.
protocol ConnectionType {
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> EventProducer
    func subscribe(topic: String) -> EventProducer
}

extension ConnectionType {
    // Convenience method to call a procedure while omitting args and/or kwargs
    func call(procedure: String, args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
        return self.call(procedure, args: args, kwargs: kwargs)
    }
}

class Connection: NSObject, MDWampClientDelegate, ConnectionType {
    
    static var sharedInstance = Connection.init()
    
    // Produces signals that passes the MDWamp object when it is available, and that handles reconnections transparently.
    lazy var producer: SignalProducer<MDWamp, ProperError> = self.connectionProducer()
    
    private static let maxConnectionFailures = 5
    private var observer: Observer<MDWamp, ProperError>?
    
    var wamp = MutableProperty<MDWamp?>(nil)
    var cache = LastEventCache()
    
    // MARK: Startup
    
    // Lazy evaluator for self.producer
    func connectionProducer() -> SignalProducer<MDWamp, ProperError> {
        NSLog("opening connection to wamp router")
        let (producer, observer) = SignalProducer<MDWamp, ProperError>.buffer(1)
        
        // Set the instance observer and connect
        self.observer = observer
        let ws = MDWampTransportWebSocket(server: Config.connection.server,
                                          protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
        let wamp = MDWamp(transport: ws, realm: Config.connection.realm, delegate: self)
        wamp.connect()
        
        // Return a producer that retries for awhile on in the event of a connection failure...
        return producer
        .retry(Connection.maxConnectionFailures).flatMapError() { _ in
            NSLog("connection failure after \(Connection.maxConnectionFailures) retries")
            return SignalProducer(error: .maxConnectionFailures)
        }
        // ...and logs all events for debugging
        .logEvents(identifier: "Connection.connectionProducer", logger: logSignalEvent)
    }
    
    // MARK: Communication Methods

    /// Subscribe to `topic` and forward parsed events. Disposing of signals created from this method will unsubscribe
    /// `topic`.
    func subscribe(topic: String) -> EventProducer {
        return self.producer
            .map { wamp in wamp.subscribeWithSignal(topic) }
            .flatten(.Latest)
            .map { TopicEvent.parseFromTopic(topic, event: $0) }
            .unwrapOrSendFailure(ProperError.eventParseFailure)
            .logEvents(identifier: "Connection.subscribe", logger: logSignalEvent)

            // Include side effects to update the last event cache.
            .on(next: { [weak self] in self?.cache.store(topic, event: $0) },
                terminated: { [weak self] in self?.cache.void(topic) })
    }

    /// Call `proc` and forward the result. Disposing the signal created will cancel the RPC call.
    func call(proc: String, args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
        // A producer that checks the cache, then completes.
        let cached = EventProducer { observer, disposable in
            self.cache.lookup(rpc: proc, args).apply(observer.sendNext)
            observer.sendCompleted()
        }.logEvents(identifier: "Connection.call (cache)", logger: logSignalEvent)


        // A producer that performs the RPC.
        let called = self.producer.map { wamp in
            wamp.callWithSignal(proc, args, kwargs, [:])
                .timeoutWithError(.timeout, afterInterval: 10.0, onScheduler: QueueScheduler.mainQueueScheduler)
            }
            .flatten(.Latest)
            .map { TopicEvent.parseFromRPC(proc, args, kwargs, $0) }
            .unwrapOrSendFailure(ProperError.eventParseFailure)
            .logEvents(identifier: "Connection.call (server)", logger: logSignalEvent)

            // Include side effects to update the last event cache.
            .on(next: { [weak self] in self?.cache.store(rpc: proc, args: args, event: $0) })

        // Return a producer that will start the cache producer first, then start the call producer. The call producer
        // which hits the network will only be called if the cache producer doesn't emit a result.
        return SignalProducer<EventProducer, ProperError>(values: [cached, called]).flatten(.Concat).take(1)
    }
    
    // MARK: MDWamp Delegate
    func mdwamp(wamp: MDWamp!, sessionEstablished info: [NSObject: AnyObject]!) {
        NSLog("session established")
        self.observer?.sendNext(wamp)
    }
    
    func mdwamp(wamp: MDWamp!, closedSession code: Int, reason: String!, details: WampKwargs!) {
        NSLog("session closed, reason: \(reason)")
        
        // MDWamp uses the `explicit_closed` key to indicate a deliberate failure.
        if reason == "MDWamp.session.explicit_closed" {
            self.observer?.sendCompleted()
            return
        }
        
        // Otherwise, it is assumed that the session closed due to an error.
        self.observer?.sendFailed(.connectionLost(reason: reason))
    }
}

// MARK: MDWamp Extensions
extension MDWamp {
    /// Follows semantics of `call` but returns a signal producer, rather than taking a result callback.
    func callWithSignal(procUri: String, _ args: WampArgs, _ argsKw: WampKwargs, _ options: [NSObject: AnyObject])
        -> SignalProducer<MDWampResult, ProperError>
    {
        return SignalProducer<MDWampResult, ProperError> { observer, _ in
            NSLog("Calling \(procUri)")
            self.call(procUri, args: args, kwArgs: argsKw, options: options) { result, error in
                if error != nil {
                    observer.sendFailed(.mdwampError(topic: procUri, object: error))
                    return
                }
                observer.sendNext(result)
                observer.sendCompleted()
            }
        }.logEvents(identifier: "MDWamp.callWithSignal", logger: logSignalEvent)
    }
    
    func subscribeWithSignal(topic: String) -> SignalProducer<MDWampEvent, ProperError> {
        return SignalProducer<MDWampEvent, ProperError> { observer, disposable in
            self.subscribe(
                topic,
                options: nil,
                onEvent: { event in observer.sendNext(event) },
                result: { error in
                    NSLog("Subscribed to \(topic)")
                    if error != nil { observer.sendFailed(.mdwampError(topic: topic, object: error)) }
                }
            )
            disposable.addDisposable {
                self.unsubscribe(topic) { error in
                    NSLog("Unsubscribed from \(topic)")
                    if error != nil { observer.sendFailed(.mdwampError(topic: topic, object: error)) }
                }
            }
        }.logEvents(identifier: "MDWamp.subscribeWithSignal", logger: logSignalEvent)
    }
}
