//
//  Transport.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MDWamp
import ReactiveCocoa

class Transport: NSObject, MDWampClientDelegate {
    static var sharedInstance = Transport.init()
    
    // Configuration
    let config: Configuration.Type
    
    private var observer: Observer<MDWamp, TransportError>?
    private lazy var producer: SignalProducer<MDWamp, TransportError> = self.connectionProducer()
    
    // When connection goes down, default to waiting this long before attempting reconnection.
    private var defaultDelay: Int64 = 1
    private var lastDelay: Int64 = 1
    
    static let maxConnectionFailures = 5

    
    required init(config: Configuration.Type = configurationForEnvironment("dev")!) {
        self.config = config
        super.init()
    }
    
    // Lazy evaluator for self.producer - should be called only once in the instance's lifetime.
    func connectionProducer() -> SignalProducer<MDWamp, TransportError> {
        NSLog("opening connection to wamp router")
        let (producer, observer) = SignalProducer<MDWamp, TransportError>.buffer(1)
        
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
        .retry(Transport.maxConnectionFailures).flatMapError() { _ in
            SignalProducer<MDWamp, TransportError>.init(error: TransportError.init(error: "max connection failures"))
        }
    }
    
    // Public facing connection to the server. Use it like this:
    //     transport.connection() { wamp in ... }
    func connection() -> Signal<MDWamp, TransportError> {
        let (signal, observer) = Signal<MDWamp, TransportError>.pipe()
        self.producer.start(observer)
        return signal
    }
    
    // MARK: MDWamp Delegate
    func mdwamp(wamp: MDWamp!, sessionEstablished info: [NSObject : AnyObject]!) {
        NSLog("session established")
        // reset the backoff delay
        self.lastDelay = self.defaultDelay
        self.observer?.sendNext(wamp)
    }
    
    func mdwamp(wamp: MDWamp!, closedSession code: Int, reason: String!, details: [NSObject : AnyObject]!) {
        NSLog("session closed, reason: \(reason)")
        self.observer?.sendCompleted() // TODO: send failure if something went wrong
    }
    
    // MARK: Model retrieval
    // TODO: move to sever commands file
//    func requestModel<Model: Base>(id: String) -> SignalProducer<Model, NSError> {
//        let (producer, observer) = SignalProducer<Model, NSError>
//        
//        if self.connection().retr
//        
//        let producer = SignalProducer<Model, NSError> { observer, _ in
//            if let wamp: MDWamp = self.wamp {
//                let cb = { r, e in self.onWampResultForObserver(observer, result: r, error: e) }
//                let rpc = "\(self.config.agency).\(Model.namespace).\(modelId)"
//                wamp.call(rpc, args: [], kwArgs: [:], options: [:], complete: cb)
//                
//            } else {
//                let error = MDWampError()
//                error.error = "wamp not connected"
//                observer.sendFailed(error.makeError())
//            }
//        }
//        
//        return producer
//    }
//    
//    func onWampResultForObserver<Model: Base>(observer: Observer<Model, NSError>, result: MDWampResult!, error: NSError!) {
//        
//    }
    
}

class TransportError: MDWampError, ErrorType {
    convenience init(error: String) {
        self.init()
        self.error = error
    }
}