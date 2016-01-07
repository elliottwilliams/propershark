//
//  ArrivalViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ArrivalViewModel: NSObject {
    private var arrival: Arrival
    private var _route: Route
    private var _vehicle: Vehicle
    
    init(_ arrival: Arrival) {
        self.arrival = arrival
        _route = arrival.trip.route
        _vehicle = arrival.trip.vehicle
    }
    
    func relativeArrivalTime() -> String {
        let relativeArrival = self.arrival.time.timeIntervalSinceNow
        let minutes = relativeArrival / 60
        let hours = relativeArrival / (60*60)
        if (minutes > 59) {
            return String(format: "in %1.0f hrs", arguments: [hours])
        } else {
            return String(format: "in %1.0f min", arguments: [minutes])
        }
    }
    
    func routeID() -> String {
        return _route.id
    }
    
    func routeName() -> String {
        return _route.name
    }
    
    func routeColor() -> UIColor {
        return _route.color
    }
    
    func vehicleCapacity() -> Double {
        return _vehicle.capacity
    }
    
    func vehicle() -> VehicleViewModel {
        return VehicleViewModel(_vehicle)
    }
}
