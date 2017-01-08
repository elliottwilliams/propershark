//
//  Arrival.swift
//  Proper
//
//  Created by Elliott Williams on 1/8/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import Argo

struct Arrival: Decodable {
    let eta: NSDate
    let etd: NSDate

    init(eta: NSDate, etd: NSDate) {
        self.eta = eta
        self.etd = etd
    }

    init(list: [NSDate]) {
        self.eta = list[0]
        self.etd = list[1]
    }

    static func decode(json: JSON) -> Decoded<Arrival> {
        return self.init <^> [NSDate].decode(json)
    }
}
