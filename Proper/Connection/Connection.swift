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

class Connection: NSObject, MDWampClientDelegate, ConfigAware {
    
    static var sharedInstance = Connection.init()
    
    // Produces signals that passes the MDWamp object when it is available, and that handles reconnections transparently.
    lazy var producer: SignalProducer<MDWamp, ConnectionError> = self.connectionProducer()
    
    internal let config: Config
    private static let maxConnectionFailures = 5
    private var observer: Observer<MDWamp, ConnectionError>?
    
    required init(config: Config = Config.sharedInstance) {
        self.config = config
        super.init()
    }
    
    // Lazy evaluator for self.producer
    func connectionProducer() -> SignalProducer<MDWamp, ConnectionError> {
        NSLog("opening connection to wamp router")
        let (producer, observer) = SignalProducer<MDWamp, ConnectionError>.buffer(1)
        
        // Set the instance observer and connect
        self.observer = observer
        let ws = MDWampTransportWebSocket(server: self.config.connection.server,
                                          protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
        let wamp = MDWamp(transport: ws, realm: self.config.connection.realm, delegate: self)
        wamp.connect()
        
        // Return a producer that disconnects when disposed...
        return producer.on(
            disposed: { wamp.disconnect() }
        )
        // ...and retries for awhile on in the event of a connection failure
        .retry(Connection.maxConnectionFailures).flatMapError() { _ in
            SignalProducer<MDWamp, ConnectionError>.init(error: ConnectionError.init(error: "max connection failures"))
        }
    }
    
    func subscribe(topic: String) -> SignalProducer<MDWampEvent, PSError> {
        return SignalProducer<MDWampEvent, PSError>.init { observer, disposable in
            self.producer.map { wamp in
                wamp.subscribe(
                    topic,
                    onEvent: { observer.sendNext($0) },
                    result: self.handleResult(observer)
                )
                disposable.addDisposable() {
                    wamp.unsubscribe(topic, result: self.handleResult(observer))
                }
            }.start()
        }
    }
    
    func call(procedure: String, args: [AnyObject]? = nil, kwargs: [NSObject: AnyObject]? = nil) -> SignalProducer<MDWampResult, PSError> {
        return SignalProducer<MDWampResult, PSError>.init { observer, _ in
            self.producer.map { wamp in
                wamp.call(procedure, args: args ?? [], kwArgs: kwargs ?? [:], options: [:]) { result, error in
                    if error != nil {
                        return observer.sendFailed(PSError(error: error, code: .mdwampError))
                    }
                    observer.sendNext(result)
                }
            }.start()
        }
    }
    
    // MDWamp uses "result" callbacks for transactional operations like (un)subscribe. This function takes an Observer and returns a function that will fail the signal on an MDWamp error.
    private func handleResult(observer: Observer<MDWampEvent, PSError>) -> (NSError!) -> Void {
        return { error in
            if error != nil {
                return observer.sendFailed(PSError(error: error, code: .mdwampError))
            }
        }
    }
    
    // MARK: MDWamp Delegate
    func mdwamp(wamp: MDWamp!, sessionEstablished info: [NSObject : AnyObject]!) {
        NSLog("session established")
        self.observer?.sendNext(wamp)
    }
    
    func mdwamp(wamp: MDWamp!, closedSession code: Int, reason: String!, details: [NSObject : AnyObject]!) {
        NSLog("session closed, reason: \(reason)")
        self.observer?.sendCompleted() // TODO: send failure if something went wrong
    }
}

class ConnectionError: MDWampError, ErrorType {
    convenience init(error: String) {
        self.init()
        self.error = error
    }
}