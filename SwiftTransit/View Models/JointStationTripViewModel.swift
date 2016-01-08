//
//  JointStationTripViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct JointStationTripViewModel {
    var trips: [TripViewModel]
    var station: StationViewModel?
    
    var vehicles: [VehicleViewModel] { return trips.map { $0.vehicle } }
    
    func hasVehicles() -> Bool {
        return self.trips.count > 0
    }
    
    func hasStation() -> Bool {
        return self.station != nil
    }
    
    func displayText() -> String? {
        return station?.name
    }
    
    func subtitleText() -> String? {
        let vehicles = trips.map { $0.vehicle }
        if hasStation() && hasVehicles() {
            return "\(pluralizedVehicles(vehicles)) arrived"
        } else if hasVehicles() {
            return "\(pluralizedVehicles(vehicles)) in transit to \(trips.first!.currentStation.name)"
        } else {
            return nil
        }
    }
    
    // Oxford comma implicit
    func pluralizedVehicles(vehicles: [VehicleViewModel]) -> String {
        if (vehicles.count == 1) {
            return "#\(vehicles.first!.id)"
        } else if (vehicles.count == 2) {
            return "#\(vehicles[0].id) and #\(vehicles[1].id)"
        } else {
            var ids = vehicles.map { "#" + $0.id }
            ids[ids.count-1] = "and " + ids[ids.count-1]
            return ids.joinWithSeparator(", ")
        }
    }
    
    func routeColor() -> UIColor? {
        return trips.first?.route.color
    }
}

