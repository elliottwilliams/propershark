//
//  Model+fixture.swift
//  Proper
//
//  Created by Elliott Williams on 9/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import ReactiveSwift
import Result
@testable import Proper

extension Decodable where Self.DecodedType == Self {
    /// Look up a decoded model fixture for `identifier`.
    static func fixture(id: String) -> SignalProducer<Self, NoError> {
        return rawFixture(id).map { Argo.decode($0) as Self! }
    }

    /// Look up a raw model fixture for `id`.
    /// Returns a SignalProducer that gets the raw (json) form of a module. For now, this searches for
    /// a `<id>.json` file in the test resource bundle, but in the future it could call the server, use a
    /// cassette system, etc.
    static func rawFixture(id: String) -> SignalProducer<AnyObject, NoError> {
        let queue = DispatchQueue.global(DispatchQueue.GlobalQueuePriority.default, 0)
        let scheduler = QueueScheduler(queue: queue, name: "ProperTests.fixtureQueue")
        return SignalProducer { observer, _ in
            dispatch_async(queue) {
                guard
                    let bundle = NSBundle(id: "ms.elliottwillia.ProperTests"),
                    let resource = bundle.pathForResource(id, ofType: "json"),
                    let data = NSData(contentsOfFile: resource),
                    let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    else {
                        fatalError("Model load error")
                }
                observer.sendNext(json)
                observer.sendCompleted()
            }
        }.observeOn(scheduler).logEvents(identifier: "Model.baseFixture", logger: logSignalEvent)
    }
}
