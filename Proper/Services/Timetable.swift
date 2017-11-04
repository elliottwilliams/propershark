//
//  Timetable.swift
//  Proper
//
//  Created by Elliott Williams on 1/5/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Argo
import Curry
import Runes

struct Timetable {
  typealias ArrivalSP = SignalProducer<Arrival, ProperError>
  typealias ArrivalListSP = SignalProducer<[Arrival], ProperError>

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
  /// - returns: A producer which sends up to one value of `[Arrival]` and completes.
  static func visits(for route: MutableRoute, at station: MutableStation, occurring timing: Timing,
                     using configs: ConfigSP, initialLimit limit: Int = defaultLimit) ->
    SignalProducer<[Arrival], ProperError>
  {
    return _visits(route: route,
                   station: station,
                   timing: timing,
                   configs: configs,
                   limit: limit)
  }

  /// Receive arrival events for vehicles scheduled to arrive at `station`.
  /// - parameters:
  ///     - station: Only search for arrivals at this station.
  ///     - timing: Temporal range to search for arrivals in. Can be unbounded (`.before(_)`, `.after(_)`) or bounded
  ///               (`.between(_,_)`).
  ///     - connection: WAMP connection that will be used to query Timetable.
  ///     - limit: Restrictions on the number of arrivals and how far ahead or behind in time they should be sent.
  /// - returns: A producer which sends up to one value of `[Arrival]` and completes.
  static func visits(for station: MutableStation, occurring timing: Timing, using configs: ConfigSP,
                     initialLimit limit: Int = defaultLimit) ->
    SignalProducer<[Arrival], ProperError>
  {
    return _visits(route: nil,
                   station: station,
                   timing: timing,
                   configs: configs,
                   limit: limit)
  }


  // MARK: - Private helpers

  private static func _visits(route: MutableRoute?,
                              station: MutableStation,
                              timing: Timing,
                              configs: ConfigSP,
                              limit: Int = defaultLimit) -> ArrivalListSP
  {
    let args: WampArgs = [route?.identifier, station.identifier].flatMap({ $0 })
      + timestamps(for: timing) as [Any]
      + [limit] as [Any]
    return configs
      // the latest connection
//      .flatMap(.latest, transform: { config in
      .flatMap(.latest, transform: { config -> SignalProducer<(Connection, String), ProperError> in
        let proc = rpc(from: timing, route: route != nil, serviceName: config.connection.scheduleService)
        return SignalProducer.combineLatest(config.connection.makeConnection(),
                                            SignalProducer(value: proc))
      })
      // the result of the call on the latest connection
      .flatMap(.latest, transform: { connection, proc in
        connection.call(proc, with: args)
          |> decodeArrivalTimes(connection: connection)
          |> log
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
        ProperError.from(decoded: decoded)
      }).attemptMap({ responses -> Result<[Arrival], ProperError> in
        ProperError.capture({ try responses.map({ try $0.makeArrival(using: connection) }) })
      })
    }
  }

  private static func rpc(from value: Timing, route: Bool, serviceName: String) -> String {
    let suffix = (route) ? "_on_route" : ""
    switch value {
    case .before(_):    return "\(serviceName).visits_before\(suffix)"
    case .after(_):     return "\(serviceName).visits_after\(suffix)"
    case .between(_):   return "\(serviceName).visits_between\(suffix)"
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
    return producer.logEvents(identifier: "Timetable", events: Set([.starting, .value, .failed]),
                              logger: logSignalEvent)
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
    func advancedBy<C: BidirectionalCollection>(arrivals: C) -> Timing
      where C.Iterator.Element == Arrival, C.Index: Comparable
    {
      guard let first = arrivals.first, let last = arrivals.last else {
        return self
      }
      switch self {
      case .before(_):
        return .before(last.eta.addingTimeInterval(-1))
      case .after(_):
        return .after(first.eta.addingTimeInterval(1))
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

  struct Response: Argo.Decodable {
    typealias DecodedType = Response
    let eta: Date
    let etd: Date
    let route: Route
    let heading: String?
    let meta: Meta

    struct Meta: Argo.Decodable {
      let realtime: Bool
      static func decode(_ json: JSON) -> Decoded<Timetable.Response.Meta> {
        return self.init <^> (json <| "realtime").or(.success(false))
      }
    }

    static func decode(_ json: JSON) -> Decoded<Response> {
      // Decode a 4-tuple: [route, heading, eta, etd]
      return [JSON].decode(json).flatMap({ args in
        guard args.count >= 4 else {
          return .failure(.custom("Expected an array of size 4"))
        }
        return curry(self.init)
          <^> Date.decode(args[0])
          <*> Date.decode(args[1])
          <*> Route.decode(args[2])
          <*> Optional<String>.decode(args[3])
          <*> Meta.decode(args[safe: 4] ?? JSON.null)
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
