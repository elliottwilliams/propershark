//
//  ArrivalsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 3/18/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import Curry

struct ArrivalsViewModel: SignalChain {
    typealias Input = SignalProducer<MutableStation, ProperError>
    typealias Output = (MutableStation, Arrival, Arrival.Lifecycle)

    // TODO - `formatter` and `preemptionTimer` should be a stored property once Swift supports static stored properties 
    // in generic types.

    static var formatter: NSDateComponentsFormatter {
        let fmt = NSDateComponentsFormatter()
        fmt.unitsStyle = .Short
        fmt.allowedUnits = [.Minute]
        return fmt
    }

    /// Produces a signal that sends the current date immediately and subsequently every second once a second on the main
    /// queue.
    static var preemptionTimer: SignalProducer<NSDate, NoError> {
        return SignalProducer() { observer, disposable in
            observer.sendNext(NSDate())
            disposable += QueueScheduler.mainQueueScheduler.scheduleAfter(NSDate(timeIntervalSinceNow: 1), repeatingEvery: 1) {
                observer.sendNext(NSDate())
            }
        }
    }

    static func chain(connection: ConnectionType, producer: SignalProducer<SignalProducer<MutableStation, ProperError>, ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer |> curry(timetable)(connection) |> lifecycle
    }

    // Produces a (station, arrival) tuple for arrivals of `station`, discovering new arrivals indefinitely.
    static func timetable(connection: ConnectionType, producer: SignalProducer<Input, ProperError>) ->
        SignalProducer<(MutableStation, Arrival), ProperError>
    {
        return producer.flatMap(.Merge, transform: { stationProducer in
            stationProducer.flatMap(.Latest, transform: { station in
                Timetable.visits(for: station,
                    occurring: .between(from: NSDate(), to: NSDate(timeIntervalSinceNow: 3600)),
                    using: connection).map({ (station, $0) })
            }).logEvents(identifier: "ArrivalsViewModel.timetable", logger: logSignalEvent)
        })
    }

    // Combines a (Station, Arrival) pair with the arrivals lifecycle. Produced values will be sent every time the
    // lifecycle state is refreshed.
    static func lifecycle(producer: SignalProducer<(MutableStation, Arrival), ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer.flatMap(.Merge, transform: { station, arrival in
            arrival.lifecycle.map({ (station, arrival, $0) })
        })
    }

    static func label(for arrival: Arrival) -> SignalProducer<String, NoError> {
        return arrival.lifecycle.combineLatestWith(preemptionTimer).map({ state, time in
            switch state {
            case .new, .upcoming:
                return formatter.stringFromDate(time, toDate: arrival.eta) ?? "Upcoming"
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
