//
//  Model+fixture.swift
//  Proper
//
//  Created by Elliott Williams on 9/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import ReactiveCocoa
@testable import Proper

extension Model where Self: Decodable, Self.DecodedType == Self {

    /// Look up a decoded model fixture for `identifier`.
    static func fixture(identifier: String) -> SignalProducer<Self, TestError> {
        return rawFixture(identifier).map { Argo.decode($0) as Self! }
    }

    /// Look up a raw model fixture for `identifier`.
    /// Returns a SignalProducer that gets the raw (json) form of a module. For now, this searches for
    /// a `<identifier>.json` file in the test resource bundle, but in the future it could call the server, use a
    /// cassette system, etc.
    static func rawFixture(identifier: String) -> SignalProducer<AnyObject, TestError> {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let scheduler = QueueScheduler(queue: queue, name: "ProperTests.fixtureQueue")
        return SignalProducer { observer, _ in
            dispatch_async(queue) {
                guard
                    let bundle = NSBundle(identifier: "ms.elliottwillia.ProperTests"),
                    let resource = bundle.pathForResource(identifier, ofType: "json"),
                    let data = NSData(contentsOfFile: resource),
                    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    else {
                        observer.sendFailed(.modelLoadError)
                        return
                }
                observer.sendNext(json)
                observer.sendCompleted()
            }
        }.observeOn(scheduler).logEvents(identifier: "Model.baseFixture", logger: logSignalEvent)
    }
}