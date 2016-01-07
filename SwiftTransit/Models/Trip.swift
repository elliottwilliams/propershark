//
//  Trip.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation
import MapKit

struct Trip {
    let vehicle: Vehicle
    let route: Route
    let currentStation: Int
    
    init(vehicle: Vehicle, route: Route, currentStationIdx: Int = 0) {
        self.vehicle = vehicle
        self.route = route
        self.currentStation = currentStationIdx
    }
    
    func withNextStationSelected() -> Trip {
        return Trip(vehicle: vehicle, route: route, currentStationIdx:
            (currentStation == route.stations.count-1) ? 0 : currentStation+1)
    }
    
    func isVehicleAtCurrentStation() -> Bool {
        let vehicleLoc = vehicle .location
        let stationLoc = route.stations[currentStation].location
        let a = CLLocation(latitude: vehicleLoc.latitude, longitude: vehicleLoc.longitude)
        let b = CLLocation(latitude: stationLoc.latitude, longitude: stationLoc.longitude)
        let dist = a.distanceFromLocation(b)
        
        // A vehicle within 30m of a station is considered at that station
        return dist <= 30.0
    }
}

extension Trip {
    func viewModel() -> TripViewModel {
        return TripViewModel(self)
    }
    
    static let DemoTrips = [
        Trip(vehicle: Vehicle.DemoVehicles[0], route: Route.DemoRoutes[2], currentStationIdx: 1),
        Trip(vehicle: Vehicle.DemoVehicles[1], route: Route.DemoRoutes[2], currentStationIdx: 1),
        Trip(vehicle: Vehicle.DemoVehicles[2], route: Route.DemoRoutes[2], currentStationIdx: 2)
    ]
}