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
    typealias Input = Set<MutableStation>
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

    static func chain(connection: ConnectionType, producer: SignalProducer<Set<MutableStation>, ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer |> curry(timetable)(connection) |> lifecycle
    }

    static func chain(connection: ConnectionType, producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<Output, ProperError>
    {
        return chain(connection, producer: producer.map(Set.init))
    }

    // Calls timetable and returns an array of (Station, Arrival) pairs.
    static func timetable(connection: ConnectionType, producer: SignalProducer<Set<MutableStation>, ProperError>) ->
        SignalProducer<[(MutableStation, Arrival)], ProperError>
    {
        return producer.flatMap(.Latest, transform: { SignalProducer<MutableStation, ProperError>(values: $0) })
            .flatMap(.Concat, transform: { station in
                combineLatest(
                    SignalProducer(value: station),
                    Timetable.visits(for: station,
                        occurring: .between(from: NSDate(), to: NSDate(timeIntervalSinceNow: 3600)),
                        using: connection)
                    ).collect()
            })
    }

    // Combines a (Station, Arrival) pair with the arrivals lifecycle. Produced values will be sent every time the
    // lifecycle state is refreshed.
    static func lifecycle(producer: SignalProducer<[(MutableStation, Arrival)], ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer.flatMap(.Latest, transform: { SignalProducer<(MutableStation, Arrival), ProperError>(values: $0) })
            .flatMap(.Merge, transform: { station, arrival in
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
