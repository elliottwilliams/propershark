//
//  NilConnection.swift
//  Proper
//
//  Created by Elliott Williams on 8/4/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
@testable import Proper

class NilConnection: ConnectionType {
  func call(_ proc: String, with args: WampArgs, kwargs: WampKwargs) -> SignalProducer<TopicEvent, ProperError> {
    // A signal producer that does nothing
    return SignalProducer { _, _ in () }
  }
  func subscribe(to topic: String) -> SignalProducer<TopicEvent, ProperError> {
    return SignalProducer { _, _ in () }
  }
}
