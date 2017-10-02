//
//  POIViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveSwift
import Curry
import Result
import Dwifft

class POIViewModel: SignalChain {
  typealias Input = [MutableStation]
  typealias Output = [Op]

  typealias Distance = CLLocationDistance
  typealias NamedPoint = (point: Point, name: String, isDeviceLocation: Bool)

  enum Op {
    case addStation(MutableStation, index: Int)
    case addArrival(Arrival, to: MutableStation)
    case deleteStation(MutableStation, at: Int)
    case deleteArrival(Arrival, from: MutableStation)
    case reorderStation(MutableStation, from: Int, to: Int)
  }

  // TODO - Maybe raise the search radius but cap the number of results returned?
  static let defaultSearchRadius = Distance(250) // in meters
  static let arrivalRowHeight = CGFloat(44)
  static let distanceFormatter = MKDistanceFormatter()


  /// Returns a producer that "seeds" the view model with the first value returned from `producer`, and then send table
  /// updates based on subsequent values from `producer`. Expected to be used with Property producers, which immediately
  /// forward their current value upon invocation.
  static func chain(connection: ConnectionType, producer stations: SignalProducer<[MutableStation], ProperError>) ->
    SignalProducer<[Op], ProperError>
  {
    let subsequent = stations.skip(first: 1)
    return stations.take(first: 1).flatMap(.latest, transform: { initial -> SignalProducer<[Op], ProperError> in
      SignalProducer<[Op], ProperError> { observer, disposable in
        // Chain from station, to station lifetimes, to arrivals, sending table operations to the view along the
        // way. This chaining is necessary to have station operations emitted _before_ arrival operations for
        // that station.
        let producer = subsequent
          |> stationOps
          |> { $0.on(value: { _, ops in observer.send(value: ops) }) }
          |> { $0.map({ stations, _ in Set(stations) }) }
          |> curry(stationPresences)(Set())
          |> curry(ArrivalsViewModel.chain)(connection)
          |> arrivalOps
          |> { $0.on(value: { ops in observer.send(value: ops) }) }

        // Start, forwarding ops and errors to the outer producer.
        disposable += producer.startWithFailed(observer.send)
      }
    })
  }

  /// Given a producer of a set of stations (e.g. a set of nearby stations which changes over time), track the
  /// *presence* or lifetime of each station. This provides a way to track how long a station continuously appears in
  /// a set.
  ///
  /// The returned producer forwards signal producers of stations. Each inner producer corresponds to exactly one
  /// station. It will send the station exactly once, the first time it appears in the set. If the station ever
  /// disappears from the set, that same producer will send an `.interrupted` event.
  ///
  /// These semantics allow for other asynchronous operations (e.g. Timetable calls and `Arrival` formation) to be
  /// bound to the lifetime of a station. It is used by `ArrivalsViewModel` to get and maintain upcoming arrivals for
  /// a station, but to stop updating arrivals (and cancel any in-flight Timetable calls) as soon as the station
  /// leaves proximity.
  ///
  /// - note: There's nothing about this function that is station-specific. It could be genericized to work with any
  /// `Hashable` element type.
  static func stationPresences(initial: Set<MutableStation>,
                               producer: SignalProducer<Set<MutableStation>, ProperError>) ->
    SignalProducer<SignalProducer<MutableStation, ProperError>, ProperError>
  {
    typealias S = SignalProducer<MutableStation, ProperError>
    typealias O = Observer<MutableStation, ProperError>

    return SignalProducer<S, ProperError> { producerObserver, disposable in
      var observers: [MutableStation: O] = [:]
      disposable += producer.combinePrevious(initial).startWithResult { result in
        guard let (prev, next) = result.value else {
          producerObserver.send(error: result.error!)
          return
        }

        // For each new station...
        next.subtracting(prev).forEach { station in
          // ...create a producer which will send the station once, and stay alive until the station
          // no longer appears in one of the sets forwarded by `producer`.
          let stationProducer = S { stationObserver, stationDisposable in
            observers[station] = stationObserver
            // Combine disposables so that disposing the outer producer propagates and disposes *this*
            // station's producer.
            disposable += stationDisposable
            stationObserver.send(value: station)
          }
          // Send this station's producer on the outer producer. Downstream observers that call `start` on the
          // producer get its station immediately, and can use the producer's lifetime to infer the
          // availability of the station.
          producerObserver.send(value: stationProducer)
        }

        // Interrupt any downstream activity once stations change.
        prev.subtracting(next).forEach { value in
          observers[value]!.sendInterrupted()
          observers[value] = nil
        }
      }
      }.logEvents(identifier: "POIViewModel.elementLifetime", logger: logSignalEvent)
  }

  static func stationOps(producer: SignalProducer<[MutableStation], ProperError>) ->
    SignalProducer<([MutableStation], [Op]), ProperError>
  {
    return producer.combinePrevious([]).map({ prev, next in
      let pi = prev.indexMap()
      let ni = next.indexMap()
      let diff = Dwifft.diff(prev, next)

      let ops = diff.flatMap({ step -> Op? in
        switch step {
        case let .insert(idx, station):
          return .addStation(station, index: idx)
//          if let p = pi[station] {
//            // If `station` had an index in `prev`, it's been moved, not inserted. Produce a reorder op...
//            return .reorderStation(station, from: p, to: idx)
//          } else {
//            return .addStation(station, index: idx)
//          }
        case let .delete(idx, station):
          return .deleteStation(station, at: idx)
//          if ni[station] == nil {
//            return .deleteStation(station, at: pi[station]!)
//          } else {
//            // ...and ignore when we get to the corresponding delete step.
//            return nil
//          }
        }
      })

      return (next, ops)
    })
  }

  static func arrivalOps(_ producer: SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>) ->
    SignalProducer<[Op], ProperError>
  {
    return producer.map({ station, arrival, state in
      switch state {
      case .new:
        return [.addArrival(arrival, to: station)]
      case .departed:
        return [.deleteArrival(arrival, from: station)]
      default:
        return []
      }
    }).filter({ !$0.isEmpty })
  }

  static func distanceString(_ producer: SignalProducer<(Point, Point), NoError>) ->
    SignalProducer<String, NoError>
  {
    return producer.map({ $0.distance(from: $1) })
      .map({ self.distanceFormatter.string(fromDistance: $0) })
  }

  static func distinctLocations(_ producer: SignalProducer<CLLocation, ProperError>) ->
    SignalProducer<NamedPoint, ProperError>
  {
    return producer.map({ $0.coordinate })
      .combinePrevious(kCLLocationCoordinate2DInvalid)
      .filter({ prev, next in
        return prev.latitude != next.latitude || prev.longitude != next.longitude })
      .map({ _, next in
        NamedPoint(point: Point(coordinate: next), name: "Current Location", isDeviceLocation: true) })
      .logEvents(identifier: "POIViewController.deviceLocation", logger: logSignalEvent)
  }
}
