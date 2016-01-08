//
//  Arrival.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct Arrival: Hashable {
    let trip: Trip
    let station: Station
    let time: NSDate
    
    var hashValue: Int { return time.hashValue }
}

func ==(a: Arrival, b: Arrival) -> Bool {
    return a.trip == b.trip && a.station == b.station && a.time == b.time
}

extension Arrival {
    func viewModel() -> ArrivalViewModel {
        return ArrivalViewModel(self)
    }
    
    static func demoArrivalForTripAndStation(trip: Trip, station: Station) -> Arrival {
        let soon = NSDate.init(timeIntervalSinceNow: 120) // 2 min from now
        return Arrival(trip: trip, station: station, time: soon)
    }
    static func demoArrivals() -> [Arrival] {
        let trip = Trip.DemoTrips[0]
        let station = trip.route.stations[0]
        return [demoArrivalForTripAndStation(trip, station: station)]
    }
}