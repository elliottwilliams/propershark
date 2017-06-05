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

struct ArrivalsViewModel: SignalChain {
  typealias Input = SignalProducer<MutableStation, ProperError>
  typealias Output = (MutableStation, Arrival, Arrival.Lifecycle)

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

  static func chain(connection: ConnectionType, producer: SignalProducer<SignalProducer<MutableStation, ProperError>, ProperError>) ->
    SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
  {
    return producer |> timetable(connection: connection) |> activate
  }

  /// Produces a (station, arrival) tuple for arrivals of `station`.
  static func timetable(connection: ConnectionType,
                        when: Timetable.Timing = .between(Date(), Date(timeIntervalSinceNow: 3600))) ->
    (_ producer: SignalProducer<Input, ProperError>) ->
    SignalProducer<(MutableStation, Arrival, Timetable.MoreCont), ProperError>
  {
    return { producer in
      return producer.flatMap(.merge, transform: { stationProducer in
        stationProducer.flatMap(.latest, transform: { station in
          Timetable.visits(
            for: station,
            occurring: when,
            using: connection
            ).map({ arrival, more in (station, arrival, more) })
        }).logEvents(identifier: "ArrivalsViewModel.timetable", logger: logSignalEvent)
      })
    }
  }

  /// Returns a producer which tracks and forwards the lifecycle state of each arrival. When an arrival departs, it
  /// will call the `MoreCont` function provided by Timetable to request an additional arrival.
  static func activate(producer: SignalProducer<(MutableStation, Arrival, Timetable.MoreCont), ProperError>) ->
    SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
  {
    return producer.flatMap(.merge, transform: { station, arrival, more in
      arrival.lifecycle.on(value: ({ state in
        if state == .departed { more() }
      })).map({ state in (station, arrival, state) })
        .promoteErrors(ProperError.self)
    })
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
