//
//  Timetable.swift
//  Proper
//
//  Created by Elliott Williams on 1/5/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import Argo

struct Timetable {
    static let defaultVisitLimit = 10

    static var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm:ss"
        return formatter
    }()

    // TODO - Cache calls to Timetable. All its RPCs are idempotent.

    enum Timing {
        case before(NSDate)
        case after(NSDate)
        case between(from: NSDate, to: NSDate)
    }

    /// Produce `limit` many arrivals for vehicles on `route` arriving at `station`, starting from `timing`.
    static func visits(for route: MutableRoute, at station: MutableStation, occurring when: Timing,
                           using connection: ConnectionType, limit: Int = defaultVisitLimit) ->
        SignalProducer<Arrival, ProperError>
    {
        let arrivalTimes = connection.call(rpc(from: when), args: [station.identifier, route.identifier] + timestamps(when))
            |> decodeArrivalTimes
        return arrivalTimes.map({ Arrival(route: route, station: station, time: $0) })
    }

    /// Produce `limit` many arrivals for vehicles of all routes of `station`, starting from `timing`. `station` must
    /// have its `routes` defined.
    static func visits(for station: MutableStation, occurring timing: Timing, using connection: ConnectionType,
                           limit: Int = defaultVisitLimit) -> SignalProducer<Arrival, ProperError>
    {
        // TODO - Once timetable#3 is implemented, use the native RPC call to get all arrivals on a station, instead of
        // calling all routes. <https://github.com/propershark/timetable_cpp/issues/3>
        let routes = station.routes.producer.flatten(.Latest)
        return routes.flatMap(.Merge, transform: { routes in
            visits(for: routes, at: station, occurring: timing, using: connection, limit: limit)
        })
    }

    private static func decodeArrivalTimes(producer: SignalProducer<TopicEvent, ProperError>) ->
        SignalProducer<ArrivalTime, ProperError>
    {
        return producer.attemptMap({ event -> Result<Decoded<[ArrivalTime]>, ProperError> in
            if case let TopicEvent.Timetable(.arrivals(arrivals)) = event {
                return .Success(arrivals)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).attemptMap({ decoded -> Result<[ArrivalTime], ProperError> in
            switch decoded {
            case .Success(let arrivals):
                return .Success(arrivals)
            case .Failure(let error):
                return .Failure(ProperError.decodeFailure(error: error))
            }
        }).flatMap(.Latest, transform: { arrivals in
            return SignalProducer<ArrivalTime, ProperError>(values: arrivals)
        })
    }

    private static func rpc(from value: Timing) -> String {
        switch value {
        case .before(_):    return "timetable.visits_before"
        case .after(_):     return "timetable.visits_after"
        case .between(_):   return "timetable.visits_between"
        }
    }

    private static func timestamps(value: Timing) -> [String] {
        let dates: [NSDate]
        switch value {
        case let .before(date):         dates = [date]
        case let .after(date):          dates = [date]
        case let .between(from, to):    dates = [from, to]
        }
        return dates.map(formatter.stringFromDate)
    }
}
