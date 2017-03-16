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
        let arrivalTimes = connection.call(rpc(from: when, route: true), args: [station.identifier] +
            timestamps(when) + [route.identifier, limit]) |> decodeArrivalTimes
        return arrivalTimes.map({ Arrival(station: station.snapshot(), message: $0) })
    }

    /// Produce `limit` many arrivals for vehicles of all routes of `station`, starting from `timing`. `station` must
    /// have its `routes` defined.
    static func visits(for station: MutableStation, occurring when: Timing, using connection: ConnectionType,
                           limit: Int = defaultVisitLimit) -> SignalProducer<Arrival, ProperError>
    {
        let arrivalTimes = connection.call(rpc(from: when, route: false), args: [station.identifier] +
            timestamps(when) + [limit]) |> decodeArrivalTimes
        return arrivalTimes.map({ Arrival(station: station.snapshot(), message: $0) })
    }

    private static func decodeArrivalTimes(producer: SignalProducer<TopicEvent, ProperError>) ->
        SignalProducer<ArrivalMessage, ProperError>
    {
        return producer.attemptMap({ event -> Result<Decoded<[ArrivalMessage]>, ProperError> in
            if case let TopicEvent.Timetable(.arrivals(arrivals)) = event {
                return .Success(arrivals)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).attemptMap({ decoded -> Result<[ArrivalMessage], ProperError> in
            switch decoded {
            case .Success(let arrivals):
                return .Success(arrivals)
            case .Failure(let error):
                return .Failure(ProperError.decodeFailure(error: error))
            }
        }).flatMap(.Latest, transform: { arrivals in
            return SignalProducer<ArrivalMessage, ProperError>(values: arrivals)
        })
    }

    private static func rpc(from value: Timing, route: Bool) -> String {
        let suffix = (route) ? "_on_route" : ""
        switch value {
        case .before(_):    return "timetable.visits_before\(suffix)"
        case .after(_):     return "timetable.visits_after\(suffix)"
        case .between(_):   return "timetable.visits_between\(suffix)"
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
