//
//  Vehicle.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/23/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation

struct Vehicle: Equatable {
    let name: String
    let id: String
    var location: (latitude: Double, longitude: Double)
    var capacity: Double
}

func ==(a: Vehicle, b: Vehicle) -> Bool {
    return a.id == b.id
}

extension Vehicle {
    func viewModel() -> VehicleViewModel {
        return VehicleViewModel(self)
    }
    
    static let DemoVehicles = [
        Vehicle(name: "Nancy", id: "BUS123", location: (40.430525, -86.913244), capacity: 0.33),
        Vehicle(name: "Hubert", id: "BUS456", location: (40.431407, -86.919531), capacity: 0.01)
    ]
}