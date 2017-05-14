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
    typealias ArrivalSP = SignalProducer<Arrival, ProperError>
    typealias ArrivalListSP = SignalProducer<[Arrival], ProperError>
    typealias MoreCont = () -> ()

    static let defaultLimit = 5
    static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm:ss"
        return formatter
    }()

    // TODO - Cache calls to Timetable. All its RPCs are idempotent.

    // MARK: - Public methods

    /// Receive arrival events for vehicles scheduled to arrive at `station` on `route`.
    /// - parameters:
    ///     - station: Only search for arrivals at this station.
    ///     - route: Only search for arrivals on this route.
    ///     - timing: Temporal range to search for arrivals in. Can be unbounded (`.before(_)`, `.after(_)`) or bounded
    ///               (`.between(_,_)`).
    ///     - connection: WAMP connection that will be used to query Timetable.
    ///     - limit: Restrictions on the number of arrivals and how far ahead or behind in time they should be sent.
    ///              Initially, up to `limit.count` arrivals will be "bursted". Afterwards, one arrival will be sent 
    ///              at a time.
    /// - returns: A producer of arrivals and a continuation function to get more arrivals.
    ///
    /// At first, `initialLimit.count` many arrivals are sent at once, followed by a new arrival every time
    /// an earlier arrival departs.
    static func visits(for route: MutableRoute, at station: MutableStation, occurring timing: Timing,
                       using connection: ConnectionType, initialLimit limit: Int = defaultLimit) ->
        SignalProducer<(arrival: Arrival, more: MoreCont), ProperError>
    {
        return _visits(route: route,
                       station: station,
                       timing: timing,
                       connection: connection,
                       initialLimit: limit)
    }

    /// Receive arrival events for vehicles scheduled to arrive at `station`.
    /// - parameters:
    ///     - station: Only search for arrivals at this station.
    ///     - timing: Temporal range to search for arrivals in. Can be unbounded (`.before(_)`, `.after(_)`) or bounded
    ///               (`.between(_,_)`).
    ///     - connection: WAMP connection that will be used to query Timetable.
    ///     - limit: Restrictions on the number of arrivals and how far ahead or behind in time they should be sent.
    ///              Initially, up to `limit.count` arrivals will be "bursted". Afterwards, one arrival will be sent 
    ///              at a time.
    /// - returns: A producer of arrivals and a continuation function to get more arrivals.
    ///
    /// At first, `initialLimit.count` many arrivals are sent at once, followed by a new arrival every time
    /// an earlier arrival departs.
    static func visits(for station: MutableStation, occurring timing: Timing, using connection: ConnectionType,
                       initialLimit limit: Int = defaultLimit) ->
        SignalProducer<(arrival: Arrival, more: MoreCont), ProperError>
    {
        return _visits(route: nil,
                       station: station,
                       timing: timing,
                       connection: connection,
                       initialLimit: limit)
    }


    // MARK: - Private helpers
    private typealias ArrivalMoreSP = SignalProducer<(arrival: Arrival, more: MoreCont), ProperError>
    private typealias ArrivalListMoreSP = SignalProducer<(arrivals: [Arrival], more: MoreCont), ProperError>

    /// RPC-agnostic producer of visits that searches beginning at `timing` and produces arrivals until
    /// interruption or when an outer bound of `timing` is hit.
    private static func _visits(route: MutableRoute?,
                                station: MutableStation,
                                timing: Timing,
                                connection: ConnectionType,
                                initialLimit: Int = defaultLimit) -> ArrivalMoreSP
    {
        let visits = ArrivalListMoreSP { observer, disposable in
            var advanced: Timing
            func send(timing: Timing, count: Int) {
                // Call Timetable and retrieve arrivals.
                let proc = rpc(from: timing, route: route != nil)
                let args: WampArgs = [route?.identifier, station.identifier].flatMap({ $0 })
                    + timestamps(for: timing)
                    + [count]
                let results = connection.call(proc, args: args)
                    |> decodeArrivalTimes(connection)
                    |> { $0.on(next: { advanced = timing.advancedBy(arrivals: $0) }) }
                    |> { $0.map({ arrivals -> (arrivals: [Arrival], more: MoreCont) in
                        // Set up a continuation function that will forward the next arrival when called.
                        let next = { send(timing: advanced, count: 1) }
                        return (arrivals, next)
                    })}
                    |> log
                disposable += results.start { event in
                    // Keep the signal open by not sending `completed` messages. Future arrivals resulting from a `more` 
                    // call will be able to flow through the signal.
                    switch event {
                    case .next(let value):      observer.sendNext(value)
                    case .completed:            break
                    case .failed(let error):    observer.sendFailed(error)
                    case .interrupted:          observer.sendInterrupted()
                    }
                }
            }

            // Get and forward the first set of arrivals for this visit query.
            send(timing: timing, count: initialLimit)
        }
        return visits.flatMap(.merge, transform: { arrivals, more -> ArrivalMoreSP in
            return SignalProducer(values: arrivals).map({ ($0, more) })
        })
    }

    private static func decodeArrivalTimes(connection: ConnectionType) ->
        (_ producer: SignalProducer<TopicEvent, ProperError>) -> ArrivalListSP
    {
        return { producer in
            return producer.attemptMap({ event -> Result<Decoded<[Response]>, ProperError> in
                if case let TopicEvent.timetable(.arrivals(arrivals)) = event {
                    return .success(arrivals)
                } else {
                    return .failure(.eventParseFailure)
                }
            }).attemptMap({ decoded -> Result<[Response], ProperError> in
                ProperError.fromDecoded(decoded)
            }).attemptMap({ responses -> Result<[Arrival], ProperError> in
                ProperError.capture({ try responses.map({ try $0.makeArrival(using: connection) }) })
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

    private static func timestamps(for value: Timing) -> [String] {
        let dates: [Date]
        switch value {
        case let .before(date):         dates = [date]
        case let .after(date):          dates = [date]
        case let .between(from, to):    dates = [from, to]
        }
        return dates.map(formatter.string(from:))
    }

    private static func log<V, E>(_ producer: SignalProducer<V, E>) -> SignalProducer<V, E> {
        return producer.logEvents(identifier: "Timetable", logger: logSignalEvent)
    }
}


// MARK: - Data structures
extension Timetable {
    // TODO - Investigate if `Timing` can be replaced with a standard Range of Dates.
    enum Timing {
        case before(Date)
        case after(Date)
        case between(Date, Date)

        /// Returns a timing range that excludes either the first arrival for chronologically ascending timings, or
        /// excluding the last arrival for chronologically descending timings.
        func advancedBy<Collection: Swift.Collection>(arrivals: Collection) -> Timing
            where Collection.Iterator.Element == Arrival, Collection.Index: Comparable
        {
            guard let first = arrivals.first, let last = arrivals.last else {
                return self
            }
            switch self {
            case .before(_):
                return .before(last.eta.addingTimeInterval(-1))
            case .after(_):
                return .after(first.eta.addingTimeInterval(1)) as (Date)
            case .between(let start, let end):
                let delta = last.eta.timeIntervalSince(start) + 1
                return .between(start.addingTimeInterval(delta), end.addingTimeInterval(delta))
            }
        }

        func advancedBy(_ arrival: Arrival) -> Timing {
            return advancedBy(arrivals: [arrival])
        }

        func advancedBy(interval ti: TimeInterval) -> Timing {
            switch self {
            case let .before(end):
                return .before(end.addingTimeInterval(-ti))
            case let .after(start):
                return .after(start.addingTimeInterval(ti))
            case let .between(start, end):
                return .between(start.addingTimeInterval(ti), end.addingTimeInterval(ti))
            }
        }

        func contains(_ date: Date) -> Bool {
            switch self {
            case let .before(end):
                return date < end
            case let .after(start):
                return date >= start
            case let .between(start, end):
                return date >= start && date < end
            }
        }
    }

    struct Response: Decodable {
        typealias DecodedType = Response
        let eta: Date
        let etd: Date
        let route: Route
        let heading: String?
        static func decode(_ json: JSON) -> Decoded<Response> {
            // Decode a 4-tuple: [route, heading, eta, etd]
            return [JSON].decode(json).flatMap({ args in
                guard args.count == 4 else {
                    return .failure(.custom("Expected an array of size 4"))
                }
                return curry(self.init)
                    <^> Date.decode(args[0])
                    <*> Date.decode(args[1])
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
}
