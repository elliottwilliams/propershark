//
//  POIViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Curry
import Result
import Dwifft

class POIViewModel: SignalChain {
    typealias Input = [MutableStation]
    typealias Output = Op

    typealias Distance = CLLocationDistance

    enum Op {
        case addStation(MutableStation, index: Int)
        case addArrival(Arrival, to: MutableStation)
        case deleteStation(MutableStation)
        case deleteArrival(Arrival, from: MutableStation)
        case reorderStation(MutableStation, index: Int)
    }

    // TODO - Maybe raise the search radius but cap the number of results returned?
    static let defaultSearchRadius = Distance(250) // in meters
    static let arrivalRowHeight = CGFloat(44)
    static let distanceFormatter = MKDistanceFormatter()

    static func chain(connection: ConnectionType,
                      producer stations: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<Op, ProperError>
    {
        let arrivals = stations |> curry(ArrivalsViewModel.chain)(connection)
        let logged = arrivals.logEvents(identifier: "POIViewModel.chain arrivals", logger: logSignalEvent)
        return SignalProducer<SignalProducer<Op, ProperError>, ProperError>(values:
            [stations |> stationOps, logged |> arrivalOps]).flatten(.Merge)
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
                    if let p = pi[station] where p > idx {
                        // If `station` had an index in `prev`, it's been moved, not inserted. Produce a reorder op...
                        return .reorderStation(station, index: idx)
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
}
