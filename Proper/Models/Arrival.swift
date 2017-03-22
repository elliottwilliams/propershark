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
    let route: MutableRoute
    let heading: String?

    var hashValue: Int {
        return eta.hashValue ^ etd.hashValue ^ route.hashValue ^ (heading?.hashValue ?? 0)
    }

    /// Emits changes to the arrival's state, following the `Arrival.Lifecycle` state machine.
    var lifecycle: SignalProducer<Lifecycle, NoError> {
        return SignalProducer(value: Lifecycle.new).concat(SignalProducer(emitLifecycle))
    }

    enum Lifecycle {
        case new
        case upcoming
        case due
        case arrived
        case departed

        static let pres: NSTimeInterval = Config.agency.timeResolution
        static let nres = -1 * pres

        /// Returns the state of this arrival, and a date to re-determine if its life is not terminated.
        static func determine(eta: NSDate, _ etd: NSDate, now: NSDate = NSDate()) -> (Lifecycle, refreshAt: NSDate?) {
            // TODO - once Arrivals can track vehicles, we should determine whether a vehicle has actually arrived at
            // its station, and can emit the `arrived` event accordingly.
            switch (eta.timeIntervalSinceNow, etd.timeIntervalSinceNow) {
            case (_, -1*Double.infinity...nres):
                return (.departed, nil)
            case (nres...pres, _),
                 (-1*Double.infinity...nres, nres...Double.infinity):
                return (.due, etd.dateByAddingTimeInterval(pres))
            default:
                return (.upcoming, eta.dateByAddingTimeInterval(nres))
            }
        }
    }

    /// Determine the current state of the arrival, send it on `observer`, and schedule the next state determination,
    /// optionally cancellable using `disposable`.
    private func emitLifecycle(observer: Observer<Lifecycle, NoError>, _ disposable: CompositeDisposable) {
        let (state, refresh) = Lifecycle.determine(eta, etd)
        observer.sendNext(state)

        if let refresh = refresh {
            disposable += QueueScheduler.mainQueueScheduler
                .scheduleAfter(refresh, action: { self.emitLifecycle(observer, disposable) })
        } else {
            observer.sendCompleted()
        }
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
