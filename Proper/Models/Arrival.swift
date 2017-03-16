//
//  Arrival.swift
//  Proper
//
//  Created by Elliott Williams on 3/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry
import ReactiveCocoa
import Result

struct Arrival: Comparable, Hashable {
    let eta: NSDate
    let etd: NSDate
    let route: Route
    let heading: String?

    var hashValue: Int {
        return eta.hashValue ^ etd.hashValue ^ route.hashValue ^ (heading?.hashValue ?? 0)
    }

    /// Emits changes to the arrival's state, following the `Arrival.Lifecycle` state machine.
    var lifecycle: SignalProducer<Lifecycle, NoError> {
        return SignalProducer(self.emitLifecycle)
    }

    enum Lifecycle {
        case upcoming
        case due
        case arrived
        case departed

        static let resolution: NSTimeInterval = Config.agency.timeResolution
        static let refresh: NSTimeInterval = 1.0
        //static let dueResolution = resolution / 5.0

        /// Compute the state given an arrival's `eta`, `etd` and `now`. Returns the lifecycle state and an optional date
        /// to re-compute.
        static func determine(eta: NSDate, _ etd: NSDate, now: NSDate = NSDate()) -> (Lifecycle, NSDate?) {
            let tta = eta.timeIntervalSinceDate(now)
            if tta < (-1 * resolution) {
                return (.departed, nil)
            } else if (-1 * resolution)...resolution ~= tta {
                return (.due, NSDate(timeIntervalSinceNow: refresh))
                // TODO - once Arrivals track vehicles, we should determine whether a vehicle has actually arrived at its
                // station, and can emit the `arrived` event accordingly.
            } else {
                return (.upcoming, NSDate(timeIntervalSinceNow: refresh))
            }
        }
    }

    /// Determine the current state of the arrival, send it on `observer`, and schedule the next state determination,
    /// optionally cancellable using `disposable`.
    private func emitLifecycle(observer: Observer<Lifecycle, NoError>, _ disposable: CompositeDisposable) {
        let (state, schedule) = Lifecycle.determine(self.eta, self.etd)
        observer.sendNext(state)

        if let schedule = schedule {
            disposable += QueueScheduler.mainQueueScheduler
                .scheduleAfter(schedule, action: { self.emitLifecycle(observer, disposable) })
        } else {
            observer.sendCompleted()
        }
    }
}

extension Arrival: Decodable {
    // Decode a 4-tuple message (the format that Timetable uses): [route, heading, eta, etd]s
    static func decode(json: JSON) -> Decoded<Arrival> {
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
}

func == (a: Arrival, b: Arrival) -> Bool {
    return a.route == b.route &&
        a.heading == b.heading &&
        a.eta == b.eta &&
        a.etd == b.etd
}

func < (a: Arrival, b: Arrival) -> Bool {
    return a.eta.compare(b.eta) == .OrderedAscending
}
