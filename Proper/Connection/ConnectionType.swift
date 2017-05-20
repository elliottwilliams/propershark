//
//  ConnectionType.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift

typealias WampArgs = [Any]
typealias WampKwargs = [AnyHashable: Any]
typealias EventProducer = SignalProducer<TopicEvent, ProperError>

// All connections conform to this protocol, which allows ConnectionMock to be injected.
protocol ConnectionType {
    func call(_ proc: String, with args: WampArgs, kwargs: WampKwargs) -> EventProducer
    func subscribe(to topic: String) -> EventProducer
}

extension ConnectionType {
    // Convenience method to call a procedure while omitting args and/or kwargs
    func call(_ proc: String, with args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
        return self.call(proc, with: args, kwargs: kwargs)
    }
}
