//
//  Arrival.swift
//  Proper
//
//  Created by Elliott Williams on 1/8/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation

struct Arrival: Comparable {
    let route: MutableRoute
    let station: MutableStation
    let time: ArrivalTime
}

func == (a: Arrival, b: Arrival) -> Bool {
    return a.route == b.route &&
        a.station == b.station &&
        a.time == b.time
}

func < (a: Arrival, b: Arrival) -> Bool {
    return a.time.eta.compare(b.time.eta) == .OrderedAscending
}
