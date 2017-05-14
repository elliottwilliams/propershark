//
//  POIViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveCocoa
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
        let subsequent = stations.skip(1)
        return stations.take(1).flatMap(.Latest, transform: { initial -> SignalProducer<[Op], ProperError> in
            SignalProducer<[Op], ProperError> { observer, disposable in
                // Chain from station, to station lifetimes, to arrivals, sending table operations to the view along the
                // way. This chaining is necessary to have station operations emitted _before_ arrival operations for 
                // that station.
                let producer = subsequent
                    |> stationOps
                    |> { $0.on(next: { _, ops in observer.sendNext(ops) }) }
                    |> { $0.map({ stations, _ in Set(stations) }) }
                    |> curry(elementLifetimes)(Set())
                    |> curry(ArrivalsViewModel.chain)(connection)
                    |> arrivalOps
                    |> { $0.on(next: { ops in observer.sendNext(ops) }) }

                // Start, forwarding ops and errors to the outer producer.
                disposable += producer.startWithFailed(observer.sendFailed)
            }
        })
    }

    /// Produces signal producers which correspond to whether particular values in `producer`'s set remain in subsequent
    /// values of `producer`.
    /// 
    /// In `POIViewModel`, this function is used to keep track of the lifetime of particular stations that are
    /// discovered, binding the discovery arrivals to the lifetime of a particular station's presence in the view.
    static func elementLifetimes<U: Hashable>(initial: Set<U>, producer: SignalProducer<Set<U>, ProperError>) ->
        SignalProducer<SignalProducer<U, ProperError>, ProperError>
    {
        typealias S = SignalProducer<U, ProperError>
        typealias O = Observer<U, ProperError>

        return SignalProducer<S, ProperError> { producers, disposable in
            var observers: [U: O] = [:]
            disposable += producer.combinePrevious(initial).startWithResult { result in
                guard let (prev, next) = result.value else {
                    producers.sendFailed(result.error!)
                    return
                }

                // Create producer for new values, and send them.
                next.subtract(prev).forEach { value in
                    let producer = S { valueObserver, valueDisposable in
                        observers[value] = valueObserver
                        disposable += valueDisposable
                        valueObserver.sendNext(value)
                    }
                    producers.sendNext(producer)
                }

                // Interrupt any downstream activity once stations change.
                prev.subtract(next).forEach { value in
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
            let diff = prev.diff(next)

            let ops = diff.results.flatMap({ step -> Op? in
                switch step {
                case let .Insert(idx, station):
                    if let p = pi[station] {
                        // If `station` had an index in `prev`, it's been moved, not inserted. Produce a reorder op...
                        return .reorderStation(station, from: p, to: idx)
                    } else {
                        return .addStation(station, index: idx)
                    }
                case let .Delete(_, station):
                    if ni[station] == nil {
                        return .deleteStation(station, at: pi[station]!)
                    } else {
                        // ...and ignore when we get to the corresponding delete step.
                        return nil
                    }
                }
            })

            return (next, ops)
        })
    }

    static func arrivalOps(producer: SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>) ->
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

    static func distanceString(producer: SignalProducer<(Point, Point), NoError>) ->
        SignalProducer<String, NoError>
    {
        return producer.map({ $0.distanceFrom($1) })
            .map({ self.distanceFormatter.stringFromDistance($0) })
    }

    static func distinctLocations(producer: SignalProducer<CLLocation, ProperError>) ->
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
