//
//  ConnectionType.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa

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
