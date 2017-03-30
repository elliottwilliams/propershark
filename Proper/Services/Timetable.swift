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

    static var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
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
    /// - returns: A producer of arrivals. Observers of this producer will receive future arrivals as their arrival time
    ///            becomes reachable within `limit`.
    ///
    /// At first, `initialLimit.count` many arrivals are sent at once, followed by a new arrival every time
    /// an earlier arrival departs.
    static func visits(for route: MutableRoute, at station: MutableStation, occurring timing: Timing,
                           using connection: ConnectionType, initialLimit limit: Limit = Limit.defaults) ->
        SignalProducer<Arrival, ProperError>
    {
        return _visits(route: route,
                       station: station,
                       interval: timing,
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
    /// - returns: A producer of arrivals. Observers of this producer will receive future arrivals as their arrival time
    ///            becomes reachable within `limit`.
    ///
    /// At first, `initialLimit.count` many arrivals are sent at once, followed by a new arrival every time
    /// an earlier arrival departs.
    static func visits(for station: MutableStation, occurring timing: Timing, using connection: ConnectionType,
                           initialLimit limit: Limit = Limit.defaults) -> SignalProducer<Arrival, ProperError>
    {
        return _visits(route: nil,
                       station: station,
                       interval: timing,
                       connection: connection,
                       initialLimit: limit)
    }


    // MARK: - Private helpers

    /// RPC-agnostic producer of visits that searches beginning at `timing` and produces arrivals until
    /// interruption or when an outer bound of `timing` is hit.
    private static func _visits(route route: MutableRoute?, station: MutableStation, interval timing: Timing,
                                      connection: ConnectionType, initialLimit: Limit) -> ArrivalSP
    {
        return caller(route, station, connection, initialLimit.count)(timing: timing, limit: initialLimit)
    }

    /// Get arrivals for `route` and `station` from Timetable, the initial response bounded by `timing` and `limit`.
    /// - parameters:
    ///     - collate: The number of arrivals to request from Timetable at a time. This is separate from `limit` to allow
    ///       for limits of count 1 without sending lots of tiny requests to Timetable.
    ///     - timing (curried): A search range used to determine the Timetable RPC and arguments. `.before(_)`, 
    ///       `.after(_)`, or `.between(_,_)`.
    ///     - limit (curried): Only send arrivals that meet these conditions.
    /// - returns: A search function that, when called with a `Timing` and `Limit`, begins producing arrivals. In the 
    ///   response from Timetable, up to `limit.count` arrivals will be forwarded at once. Subsequently, the next arrival
    ///   will be forwarded whenever an earlier arrival departs.
    private static func caller(route: MutableRoute?, _ station: MutableStation, _ connection: ConnectionType, _ collate: Int) ->
        (timing: Timing, limit: Limit) -> ArrivalSP
    {
        return { timing, limit in
            let proc = rpc(from: timing, route: route != nil)
            let args: WampArgs = [route?.identifier, station.identifier].flatMap({ $0 })
                + timestamps(timing)
                + [collate]
            let again = caller(route, station, connection, collate)
            let send = sender(timing, limit, again)
            return connection.call(proc, args: args)
                |> decodeArrivalTimes(connection)
                |> { $0.collect(count: limit.count).flatMap(.Concat, transform: send) }
                |> log
        }
    }

    /// Deliver arrivals within bounds of `timing` and `limit`, and schedule the delivery of future arrivals obtained
    /// by calling the continuation `more`.
    /// - parameters:
    ///     - timing: The search bounds used in the Timetable call that this `sender` will be sending. The bounds are used
    ///       to calculate a new interval when searching should continue.
    ///     - limit: Only send arrivals that meet the criteria within.
    ///     - more: A continuation that searches for more arrivals, given a `Timing` and `Limit` to search within.
    /// - returns: A closure that, given a list of arrivals, returns a a producer which bursts up to `limit` arrivals 
    ///   early on, then sends arrivals one at time as they fit into `limit`.
    private static func sender(timing: Timing, _ limit: Limit, _ more: (Timing, Limit) -> ArrivalSP) ->
        ([Arrival]) -> ArrivalSP
    {
        let one = Limit(window: limit.window, count: 1)
        return { arrivals in
            let (sent, unsent) = limit.split(arrivals, timing: timing)
            guard let first = sent.first else {
                return SignalProducer.empty
            }
            
            return SignalProducer { observer, disposable in
                // Send response and schedule the next response.
                sent.forEach { observer.sendNext($0) }
                disposable += QueueScheduler.mainQueueScheduler.scheduleAfter(first.etd) {
                    if unsent.isEmpty {
                        let newTiming = timing.without(arrivals: sent)
                        disposable += more(newTiming, one).start(observer)
                    } else {
                        disposable += sender(timing, one, more)(Array(unsent)).start(observer)
                    }
                }
            }
        }
    }
    
    private static func decodeArrivalTimes(connection: ConnectionType) ->
        (producer: SignalProducer<TopicEvent, ProperError>) -> ArrivalSP
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
                ArrivalSP(values: arrivals)
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

    private static func log(producer: ArrivalSP) -> ArrivalSP {
        return producer.logEvents(identifier: "Timetable", logger: logSignalEvent)
    }
}


// MARK: - Data structures
extension Timetable {
    enum Timing {
        case before(NSDate)
        case after(NSDate)
        case between(NSDate, NSDate)

        /// Returns a timing range that excludes either the first arrival for chronologically ascending timings, or
        /// excluding the last arrival for chronologically descending timings.
        func without<Collection: CollectionType where Collection.Generator.Element == Arrival,
            Collection.Index: BidirectionalIndexType>
            (arrivals arrivals: Collection) -> Timing
        {
            guard let first = arrivals.first, last = arrivals.last else {
                return self
            }
            switch self {
            case .before(_):
                return .before(last.eta.dateByAddingTimeInterval(-1))
            case .after(_):
                return .after(first.eta.dateByAddingTimeInterval(1))
            case .between(_, let end):
                return .between(last.eta.dateByAddingTimeInterval(1), end)
            }
        }

        func without(interval ti: NSTimeInterval) -> Timing {
            switch self {
            case let .before(end):
                return .before(end.dateByAddingTimeInterval(-ti))
            case let .after(start):
                return .after(start.dateByAddingTimeInterval(ti))
            case let .between(start, end):
                return .between(start.dateByAddingTimeInterval(ti), end)
            }
        }

        func contains(date: NSDate) -> Bool {
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

    struct Limit {
        let window: NSTimeInterval
        let count: Int

        static let defaults = Limit(window: 3600, count: 5)

        func split(arrivals: [Arrival], timing: Timing) -> (insideLimit: ArraySlice<Arrival>, outside: ArraySlice<Arrival>) {
            let outside = timing.without(interval: window)
            // TODO - swift 3 - use first(where:) to not short circuit the filter
            let idx = arrivals.enumerate().filter({ $0 >= self.count || outside.contains($1.eta) }).first?.index
            if let idx = idx {
                return (arrivals.prefixUpTo(idx), arrivals.suffixFrom(idx))
            } else {
                return (ArraySlice(arrivals), ArraySlice())
            }
        }
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
}
