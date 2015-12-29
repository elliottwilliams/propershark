//
//  Trip.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation

struct Trip {
    var vehicle: Vehicle
    var route: Route
}

extension Trip {
    static let DemoTrips = [
        Trip(vehicle: Vehicle.DemoVehicles[0], route: Route.DemoRoutes[2])
    ]
}