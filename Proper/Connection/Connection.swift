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

typealias WampArgs = [AnyObject]
typealias WampKwargs = [NSObject: AnyObject]

struct WampRPCCall {
    let topic: String
    let args: WampArgs
    let kwargs: WampKwargs
}

// All connections conform to this protocol, which allows ConnectionMock to be injected.
protocol ConnectionType {
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> SignalProducer<TopicEvent, PSError>
    func subscribe(topic: String) -> SignalProducer<TopicEvent, PSError>
}

extension ConnectionType {
    // Convenience method to call a procedure while omitting args and/or kwargs
    func call(procedure: String, args: WampArgs = [], kwargs: WampKwargs = [:]) -> SignalProducer<TopicEvent, PSError> {
        return self.call(procedure, args: args, kwargs: kwargs)
    }
}

class Connection: NSObject, MDWampClientDelegate, ConnectionType {
    
    static var sharedInstance = Connection.init()
    
    // Produces signals that passes the MDWamp object when it is available, and that handles reconnections transparently.
    lazy var producer: SignalProducer<MDWamp, PSError> = self.connectionProducer()
    
    private lazy var config: Config = Config.sharedInstance
    private static let maxConnectionFailures = 5
    private var observer: Observer<MDWamp, PSError>?
    
    var wamp = MutableProperty<MDWamp?>(nil)
    
    // MARK: Startup
    
    // Lazy evaluator for self.producer
    func connectionProducer() -> SignalProducer<MDWamp, PSError> {
        NSLog("opening connection to wamp router")
        let (producer, observer) = SignalProducer<MDWamp, PSError>.buffer(1)
        
        // Set the instance observer and connect
        self.observer = observer
        let ws = MDWampTransportWebSocket(server: self.config.connection.server,
                                          protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
        let wamp = MDWamp(transport: ws, realm: self.config.connection.realm, delegate: self)
        wamp.connect()
        
        // Return a producer that retries for awhile on in the event of a connection failure...
        return producer
        .retry(Connection.maxConnectionFailures).flatMapError() { _ in
            NSLog("connection failure after \(Connection.maxConnectionFailures) retries")
            return SignalProducer<MDWamp, PSError>.init(error: PSError(code: .maxConnectionFailures))
        }
        // ...and logs all events for debugging
        .logEvents(identifier: "Connection.connectionProducer", logger: logSignalEvent)
    }
    
    // MARK: Communication Methods

    /// Subscribe to `topic` and forward parsed events. Disposing of signals created from this method will unsubscribe
    /// `topic`.
    func subscribe(topic: String) -> SignalProducer<TopicEvent, PSError> {
        return self.producer
        .map { wamp in wamp.subscribeWithSignal(topic) }
        .flatten(.Latest)
        .attemptMap { (wampEvent: MDWampEvent) in
            if let event = TopicEvent.parseFromTopic(topic, event: wampEvent) {
                return .Success(event)
            } else {
                return .Failure(PSError(code: .parseFailure))
            }
        }
        .logEvents(identifier: "Connection.subscribe(topic:\"\(topic)\")", logger: logSignalEvent)
    }

    /// Call `procdure` and forward the result. Disposing the signal created will cancel the RPC call.
    func call(topic: String, args: WampArgs = [], kwargs: WampKwargs = [:]) -> SignalProducer<TopicEvent, PSError> {
        return self.producer.map { wamp in
        wamp.callWithSignal(topic, args, kwargs, [:])
            .timeoutWithError(PSError(code: .timeout), afterInterval: 10.0, onScheduler: QueueScheduler.mainQueueScheduler)
        }
        .flatten(.Latest)
        .attemptMap { wampEvent in
            if let event = TopicEvent.parseFromRPC(topic, args, kwargs, wampEvent) {
                return .Success(event)
            } else {
                return .Failure(PSError(code: .parseFailure))
            }
        }
        .logEvents(identifier: "Connection.call(procedure:\"\(topic)\")", logger: logSignalEvent)
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
        let errorDict = [NSUnderlyingErrorKey: reason]
        self.observer?.sendFailed(PSError(code: .connectionLost, userInfo: errorDict))
    }
}

// MARK: MDWamp Extensions
extension MDWamp {
    /// Follows semantics of `call` but returns a signal producer, rather than taking a result callback.
    func callWithSignal(procUri: String, _ args: WampArgs, _ argsKw: WampKwargs, _ options: [NSObject: AnyObject])
        -> SignalProducer<MDWampResult, PSError>
    {
        return SignalProducer<MDWampResult, PSError> { observer, _ in
            NSLog("Calling \(procUri)")
            self.call(procUri, args: args, kwArgs: argsKw, options: options) { result, error in
                if error != nil {
                    observer.sendFailed(PSError(error: error, code: .mdwampError, associated: procUri))
                    return
                }
                observer.sendNext(result)
                observer.sendCompleted()
            }
        }.logEvents(identifier: "MDWamp.callWithSignal", logger: logSignalEvent)
    }
    
    func subscribeWithSignal(topic: String) -> SignalProducer<MDWampEvent, PSError> {
        return SignalProducer<MDWampEvent, PSError> { observer, disposable in
            self.subscribe(
                topic,
                onEvent: { event in observer.sendNext(event) },
                result: { error in
                    NSLog("Subscribed to \(topic)")
                    if error != nil { observer.sendFailed(PSError(error: error, code: .mdwampError, associated: topic)) }
                }
            )
            disposable.addDisposable {
                self.unsubscribe(topic) { error in
                    NSLog("Unsubscribed from \(topic)")
                    if error != nil { observer.sendFailed(PSError(error: error, code: .mdwampError, associated: topic)) }
                }
            }
        }.logEvents(identifier: "MDWamp.subscribeWithSignal", logger: logSignalEvent)
    }
}