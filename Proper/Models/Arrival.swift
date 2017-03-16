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

struct Arrival: Comparable, Hashable {
    // TODO - Refactor ArrivalTime into this class, it's no longer used separately.
    let time: ArrivalTime
    let route: Route
    let heading: String?

    var hashValue: Int {
        return route.hashValue ^ time.hashValue ^ (heading?.hashValue ?? 0)
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
                <^> ArrivalTime.decode(JSON.Array(Array(args.prefixThrough(1))))
                <*> Route.decode(args[2])
                <*> Optional<String>.decode(args[3])
        })
    }
}

func == (a: Arrival, b: Arrival) -> Bool {
    return a.route == b.route &&
        a.heading == b.heading &&
        a.time == b.time
}

func < (a: Arrival, b: Arrival) -> Bool {
    return a.time < b.time
}
