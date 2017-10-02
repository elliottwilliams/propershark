//
//  ArrivalsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 3/18/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Curry

struct ArrivalsViewModel {
  // TODO - `formatter` and `preemptionTimer` should be a stored property once Swift supports static stored properties
  // in generic types.

  static var formatter: DateComponentsFormatter {
    let fmt = DateComponentsFormatter()
    fmt.unitsStyle = .short
    fmt.allowedUnits = [.minute]
    return fmt
  }

  /// Produces a signal that sends the current date immediately and subsequently every second once a second on the main
  /// queue.
  static var preemptionTimer: SignalProducer<Date, NoError> {
    return SignalProducer() { observer, disposable in
      observer.send(value: Date())

      disposable += QueueScheduler.main.schedule(after: Date.init(timeIntervalSinceNow: 1), interval: .seconds(1)) {
        observer.send(value: Date())
      }
    }
  }

  static func label(for arrival: Arrival) -> SignalProducer<String, NoError> {
    return arrival.lifecycle.combineLatest(with: preemptionTimer).map({ state, time in
      switch state {
      case .new, .upcoming:
        return formatter.string(from: time, to: arrival.eta) ?? "Upcoming"
      case .due:
        return "Due"
      case .arrived:
        return "Arrived"
      case .departed:
        return "Departed"
      }
    })
  }
}
