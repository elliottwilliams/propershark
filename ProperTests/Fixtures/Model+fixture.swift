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
    return rawFixture(id: id).map { Argo.decode($0) as Self! }
  }

  /// Look up a raw model fixture for `id`.
  /// Returns a SignalProducer that gets the raw (json) form of a module. For now, this searches for
  /// a `<id>.json` file in the test resource bundle, but in the future it could call the server, use a
  /// cassette system, etc.
  static func rawFixture(id: String) -> SignalProducer<Any, NoError> {
    let scheduler = QueueScheduler(qos: .default, name: "ProperTests.fixtureLoeader")
    return SignalProducer { observer, _ in
      scheduler.schedule {
        guard
          let bundle = Bundle(identifier: "ms.elliottwillia.ProperTests"),
          let resource =  bundle.path(forResource: id, ofType: "json"),
          let data = NSData(contentsOfFile: resource),
          let json = try? JSONSerialization.jsonObject(with: data as Data)
          else {
            fatalError("Model load error")
        }
        observer.send(value: json)
        observer.sendCompleted()
      }
      }.observe(on: scheduler).logEvents(identifier: "Model.baseFixture", logger: logSignalEvent)
  }
}
