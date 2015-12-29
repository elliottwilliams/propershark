//
//  Station.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation
import MapKit

struct Station {
    var name: String
    var id: String
    var neighborhood: [String]?
    var location: (latitude: Double, longitude: Double)
}

extension Station {
    static let DemoStations = [
        Station(name: "Purdue Memorial Union", id: "BUS123", neighborhood: [], location: (40.4246641, -86.9115902)),
        Station(name: "Electrical Engineering", id: "BUS456", neighborhood: [],
            location: (40.4284618, -86.9116224)),
        Station(name: "Columbia & Northwestern", id: "BUS789", neighborhood: [],
            location: (40.4249377, -86.9083984))
    ]
}