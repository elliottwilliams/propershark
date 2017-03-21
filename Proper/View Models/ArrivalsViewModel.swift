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

struct ArrivalsViewModel<C: CollectionType where C.Generator.Element == MutableStation>: SignalChain {
    typealias Input = C
    typealias Output = (MutableStation, Arrival, Arrival.Lifecycle)

    static func timetable(connection: ConnectionType, producer: SignalProducer<C, ProperError>) ->
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

    static func lifecycle(producer: SignalProducer<[(MutableStation, Arrival)], ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer.flatMap(.Latest, transform: { SignalProducer<(MutableStation, Arrival), ProperError>(values: $0) })
            .flatMap(.Merge, transform: { station, arrival in
                arrival.lifecycle.map({ (station, arrival, $0) })
            })
    }

    static func chain(connection: ConnectionType, producer: SignalProducer<C, ProperError>) ->
        SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>
    {
        return producer |> curry(timetable)(connection) |> lifecycle
    }
}
