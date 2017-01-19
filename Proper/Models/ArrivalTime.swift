//
//  ArrivalTime.swift
//  Proper
//
//  Created by Elliott Williams on 1/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import Argo

struct ArrivalTime: Decodable, Comparable, Hashable {
    let eta: NSDate
    let etd: NSDate

    var hashValue: Int {
        return eta.hashValue ^ etd.hashValue
    }

    init(eta: NSDate, etd: NSDate) {
        self.eta = eta
        self.etd = etd
    }

    init(list: [NSDate]) {
        self.eta = list[0]
        self.etd = list[1]
    }

    static func decode(json: JSON) -> Decoded<ArrivalTime> {
        return self.init <^> [NSDate].decode(json)
    }
}

func == (a: ArrivalTime, b: ArrivalTime) -> Bool {
    return a.eta == b.eta && a.etd == b.etd
}

func < (a: ArrivalTime, b: ArrivalTime) -> Bool {
    return a.eta.compare(b.eta) == .OrderedAscending
}
