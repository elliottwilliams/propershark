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
import Curry

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

    struct Response: Decodable {
        let eta: NSDate
        let etd: NSDate
        let route: Route
        let heading: String?
        static func decode(json: JSON) -> Decoded<Response> {
            // Decode a 4-tuple: [route, heading, eta, etd]
            return [JSON].decode(json).flatMap({ args in
                guard args.count == 4 else {
                    return .Failure(.Custom("Expected an array of size 4"))
                }
                return curry(self.init)
                    <^> NSDate.decode(args[0])
                    <*> NSDate.decode(args[1])
                    <*> Route.decode(args[2])
                    <*> Optional<String>.decode(args[3])
            })
        }
        func makeArrival(using connection: ConnectionType) throws -> Arrival {
            do {
                let mutable = try MutableRoute(from: route, connection: connection)
                return Arrival(eta: eta, etd: etd, route: mutable, heading: heading)
            }
        }
    }

    /// Produce `limit` many arrivals for vehicles on `route` arriving at `station`, starting from `timing`.
    static func visits(for route: MutableRoute, at station: MutableStation, occurring when: Timing,
                           using connection: ConnectionType, limit: Int = defaultVisitLimit) ->
        SignalProducer<Arrival, ProperError>
    {
        return connection.call(rpc(from: when, route: true), args: [station.identifier] +
            timestamps(when) + [route.identifier, limit]) |> decodeArrivalTimes(connection)
    }

    /// Produce `limit` many arrivals for vehicles of all routes of `station`, starting from `timing`. `station` must
    /// have its `routes` defined.
    static func visits(for station: MutableStation, occurring when: Timing, using connection: ConnectionType,
                           limit: Int = defaultVisitLimit) -> SignalProducer<Arrival, ProperError>
    {
        return connection.call(rpc(from: when, route: false), args: [station.identifier] +
            timestamps(when) + [limit]) |> decodeArrivalTimes(connection)
    }

    private static func decodeArrivalTimes(connection: ConnectionType) ->
        (producer: SignalProducer<TopicEvent, ProperError>) ->
        SignalProducer<Arrival, ProperError>
    {
        return { producer in
            return producer.attemptMap({ event -> Result<Decoded<[Response]>, ProperError> in
                if case let TopicEvent.Timetable(.arrivals(arrivals)) = event {
                    return .Success(arrivals)
                } else {
                    return .Failure(.eventParseFailure)
                }
            }).attemptMap({ decoded -> Result<[Response], ProperError> in
                ProperError.fromDecoded(decoded)
            }).attemptMap({ responses -> Result<[Arrival], ProperError> in
                ProperError.capture({ try responses.map({ try $0.makeArrival(using: connection) }) })
            }).flatMap(.Latest, transform: { arrivals in
                SignalProducer<Arrival, ProperError>(values: arrivals)
            })
        }
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
