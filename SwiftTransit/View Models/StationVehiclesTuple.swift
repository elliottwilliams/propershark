//
//  TripsForStation.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class TripsForStation: NSObject {
    var trips: [TripViewModel]
    var station: StationViewModel?
    
    init(trips: [TripViewModel], station: StationViewModel?) {
        self.trips = trips
        self.station = station
    }
    
    func hasVehicles() -> Bool {
        return self.trips.count > 0
    }
    
    func hasStation() -> Bool {
        return self.station != nil
    }
    
    func displayText() -> String {
        if (hasStation()) {
            return station!.name
        } else {
            return "In transit to \(trips.first!.currentStation.name)"
        }
    }
    
    func subtitleText() -> String? {
        if hasStation() && hasVehicles() {
            if trips.count == 1 {
                return "Bus \(trips.first!._vehicle.id) arrived"
            } else {
                var ids = trips.map { $0._vehicle.id }
                ids[ids.count-1] = "and " + ids[ids.count-1]
                return "Buses \(ids.joinWithSeparator(",")) arrived"
            }
        } else {
            return nil
        }
    }
}

