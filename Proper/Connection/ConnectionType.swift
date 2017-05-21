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
    func call(_ proc: String) -> EventProducer {
        return call(proc, with: [], kwargs: [:])
    }
    func call(_ proc: String, with args: WampArgs) -> EventProducer {
        return call(proc, with: args, kwargs: [:])
    }
    func call(_ proc: String, kwargs: WampKwargs) -> EventProducer {
        return call(proc, with: [], kwargs: kwargs)
    }

}
