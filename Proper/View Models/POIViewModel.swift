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
    typealias Output = Op

    typealias Distance = CLLocationDistance
    typealias NamedPoint = (point: Point, name: String, isDeviceLocation: Bool)

    enum Op {
        case addStation(MutableStation, index: Int)
        case addArrival(Arrival, to: MutableStation)
        case deleteStation(MutableStation)
        case deleteArrival(Arrival, from: MutableStation)
        case reorderStation(MutableStation, from: Int, to: Int)
    }

    // TODO - Maybe raise the search radius but cap the number of results returned?
    static let defaultSearchRadius = Distance(250) // in meters
    static let arrivalRowHeight = CGFloat(44)
    static let distanceFormatter = MKDistanceFormatter()


    /// Returns a producer that "seeds" the view model with the first value returned from `producer`, and then updates
    /// table with subsequent values from `producer`. Expected to be used with Property producers, which immediately
    /// forward their current value upon invocation.
    static func chain(connection: ConnectionType, producer property: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<Op, ProperError>
    {
        let subsequent = property.skip(1)
        return property.take(1).flatMap(.Latest, transform: { initial -> SignalProducer<Op, ProperError> in
            let arrivals = subsequent
                |> onlyNewStations(given: initial)
                |> curry(ArrivalsViewModel.chain)(connection)
            let logged = arrivals.logEvents(identifier: "POIViewModel.chain arrivals", logger: logSignalEvent)
            return SignalProducer<SignalProducer<Op, ProperError>, ProperError>(values:
                [subsequent |> stationOps, logged |> arrivalOps]).flatten(.Merge)
        })

    }

    static func onlyNewStations(given previous: [MutableStation]) ->
        (producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<Set<MutableStation>, ProperError>
    {
        return { producer in
            return producer.map(Set.init).combinePrevious(Set(previous)).map({ prev, next in
                next.subtract(prev)
            })
        }
    }

    static func stationOps(producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<Op, ProperError>
    {
        return producer.combinePrevious([]).flatMap(.Latest, transform: { prev, next -> SignalProducer<Op, ProperError> in
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
                        return .deleteStation(station)
                    } else {
                        // ...and ignore when we get to the corresponding delete step.
                        return nil
                    }
                }
            })

            return SignalProducer(values: ops)
        })
    }

    static func arrivalOps(producer: SignalProducer<(MutableStation, Arrival, Arrival.Lifecycle), ProperError>) ->
        SignalProducer<Op, ProperError>
    {
        return producer.map({ station, arrival, state -> Op? in
            switch state {
            case .new:
                return .addArrival(arrival, to: station)
            case .departed:
                return .deleteArrival(arrival, from: station)
            default:
                return nil
            }
        }).ignoreNil()
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
