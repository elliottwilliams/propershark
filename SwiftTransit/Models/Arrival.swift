//
//  Arrival.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct Arrival: Hashable, CustomStringConvertible {
    let trip: Trip
    let station: Station
    let time: NSDate
    
    var hashValue: Int { return time.hashValue }
    var description: String { return "Arrival(trip: \(trip), station: \(station))" }
    
    func isVehicleAtStation() -> Bool {
        let vehicleLoc = self.trip.vehicle.location
        let stationLoc = self.station.location
        let a = CLLocation(latitude: vehicleLoc.latitude, longitude: vehicleLoc.longitude)
        let b = CLLocation(latitude: stationLoc.latitude, longitude: stationLoc.longitude)
        let dist = a.distanceFromLocation(b)
        
        // A vehicle within 30m of a station is considered at that station
        return dist <= 30.0
    }
}

func ==(a: Arrival, b: Arrival) -> Bool {
    return a.trip == b.trip && a.station == b.station && a.time == b.time
}

extension Arrival {
    func viewModel() -> ArrivalViewModel {
        return ArrivalViewModel(self)
    }
    
    func withAdvancedStation() -> Arrival {
        let i = trip.route.stations.indexOf(station)!
        let nextStation = trip.route.stations[safe: i+1] ?? trip.route.stations[0]
        return Arrival(trip: trip, station: nextStation, time: Arrival.twoMinFromNow())
    }
    
    static func twoMinFromNow() -> NSDate {
        return NSDate.init(timeIntervalSinceNow: 120) // 2 min from now
    }
    static func demoArrivalForTripAndStation(trip: Trip, station: Station) -> Arrival {
        let soon = twoMinFromNow()
        return Arrival(trip: trip, station: station, time: soon)
    }
    static func demoArrivals() -> [Arrival] {
        let t1 = Trip.DemoTrips[0]
        let t2 = Trip.DemoTrips[1]
        let t3 = Trip.DemoTrips[2]
        return [
            demoArrivalForTripAndStation(t1, station: t1.route.stations[0]),
            demoArrivalForTripAndStation(t2, station: t2.route.stations[0]),
            demoArrivalForTripAndStation(t3, station: t3.route.stations[1])
        ]
    }
}