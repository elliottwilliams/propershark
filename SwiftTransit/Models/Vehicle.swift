//
//  Vehicle.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/23/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation

struct Vehicle {
    var name: String
    var id: String
    var location: (latitude: Double, longitude: Double)
    var capacity: Double
}

extension Vehicle {
    static let DemoVehicles = [
        Vehicle(name: "Nancy", id: "BUS123", location: (40.430525, -86.913244), capacity: 0.33),
        Vehicle(name: "Hubert", id: "BUS456", location: (40.431407, -86.919531), capacity: 0.01)
    ]
}