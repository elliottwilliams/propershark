//
//  AdaptiveReconnecting.swift
//  Proper
//
//  Created by Elliott Williams on 11/4/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

extension SignalProducer {
  func restarting(every interval: TimeInterval, on scheduler: QueueScheduler) -> SignalProducer<Value, Error> {
    return flatMapError({ error in
      NSLog("\(self): error - \(error), restarting in \(interval)")
      return SignalProducer.empty.delay(interval, on: scheduler)
        .concat(self.restarting(every: interval, on: scheduler))
    }).logEvents(identifier: "SignalProducer.restarting", logger: logSignalEvent)
  }
}
