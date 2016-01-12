//
//  Vehicle.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/23/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation

struct Vehicle: Hashable, CustomStringConvertible {
    let name: String
    let id: String
    var location: (latitude: Double, longitude: Double)
    var capacity: Double
    
    var hashValue: Int { return self.id.hashValue }
    var description: String { return "Vehicle(id: \(self.id), name: \(self.name))" }
}

func ==(a: Vehicle, b: Vehicle) -> Bool {
    return a.id == b.id
}

extension Vehicle {
    func viewModel() -> VehicleViewModel {
        return VehicleViewModel(self)
    }
    
    static let DemoVehicles = [
        Vehicle(name: "Nancy", id: "123", location: (40.430525, -86.913244), capacity: 0.33),
        Vehicle(name: "Hubert", id: "456", location: (40.431407, -86.919531), capacity: 0.01),
        Vehicle(name: "Francis", id: "789", location: (40.4249377, -86.9083984), capacity: 0.7)
    ]
}