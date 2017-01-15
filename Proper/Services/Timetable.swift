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

    /// Produce the next `limit` arrivals of `route` on `station`, starting from `beginTime`.
    static func visits(for route: MutableRoute, at station: MutableStation, after beginTime: NSDate,
                       using connection: ConnectionType = Connection.cachedInstance,
                       limit: Int = defaultVisitLimit) -> SignalProducer<Arrival, ProperError>
    {
        return visits(rpc: "timetable.next_visits", for: route, at: station, time: beginTime, using: connection,
                      limit: limit)
    }

    /// Produce the last `limit` arrivals of `route` on `station`, looking backwards from `endTime`.
    static func visits(for route: MutableRoute, at station: MutableStation, before endTime: NSDate,
                       using connection: ConnectionType = Connection.cachedInstance,
                       limit: Int = defaultVisitLimit) -> SignalProducer<Arrival, ProperError>
    {
        return visits(rpc: "timetable.last_visits", for: route, at: station, time: endTime, using: connection,
                      limit: limit)
    }

    // Internal visit function to call either `next_visits` or `last_visits`.
    private static func visits(rpc rpc: String, for route: MutableRoute, at station: MutableStation,
                                   time: NSDate, using connection: ConnectionType, limit: Int) ->
        SignalProducer<Arrival, ProperError>
    {
        return connection.call(rpc, args: [station.identifier, route.identifier, timestamp(time),
            limit]) |> decodeArrivals
    }

    private static func decodeArrivals(producer: SignalProducer<TopicEvent, ProperError>) ->
        SignalProducer<Arrival, ProperError>
    {
        return producer.attemptMap({ event -> Result<Decoded<[Arrival]>, ProperError> in
            if case let TopicEvent.Timetable(.arrivals(arrivals)) = event {
                return .Success(arrivals)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).attemptMap({ decoded -> Result<[Arrival], ProperError> in
            switch decoded {
            case .Success(let arrivals):
                return .Success(arrivals)
            case .Failure(let error):
                return .Failure(ProperError.decodeFailure(error: error))
            }
        }).flatMap(.Latest, transform: { arrivals in
            return SignalProducer<Arrival, ProperError>(values: arrivals)
        })
    }

    static var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm:ss"
        return formatter
    }()

    private static func timestamp(date: NSDate) -> String {
        return formatter.stringFromDate(date)
    }
}
