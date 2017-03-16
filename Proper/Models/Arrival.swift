//
//  Arrival.swift
//  Proper
//
//  Created by Elliott Williams on 1/8/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation

struct Arrival: Comparable, Hashable {
    let route: Route
    let station: Station
    let heading: String?
    let time: ArrivalTime

    var hashValue: Int {
        return route.hashValue ^ station.hashValue ^ time.hashValue
    }

    init(route: Route, station: Station, heading: String?, time: ArrivalTime) {
        self.route = route
        self.station = station
        self.heading = heading
        self.time = time
    }

    init(station: Station, message: ArrivalMessage) {
        self.station = station
        route = message.route
        heading = message.heading
        time = message.time
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
