//
//  Arrival.swift
//  Proper
//
//  Created by Elliott Williams on 1/8/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation

struct Arrival: Comparable, Hashable {
    let route: MutableRoute
    let station: MutableStation
    let time: ArrivalTime

    var hashValue: Int {
        return route.hashValue ^ station.hashValue ^ time.hashValue
    }
}

func == (a: Arrival, b: Arrival) -> Bool {
    return a.route == b.route &&
        a.station == b.station &&
        a.time == b.time
}

func < (a: Arrival, b: Arrival) -> Bool {
    return a.time < b.time
}
