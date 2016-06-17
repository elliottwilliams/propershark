//
//  ArrivalViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct ArrivalViewModel: Hashable, CustomStringConvertible {
    
    // MARK: Immutable properties
    
    let _arrival: Arrival
    let _route: Route
    let _vehicle: Vehicle
    let isInTransit: Bool
    let hasArrived: Bool
    
    // MARK: Computed properties
    
    var trip: TripViewModel { return _arrival.trip.viewModel() }
    var station: StationViewModel { return _arrival.station.viewModel().withIsInTransit(self.isInTransit) }
    var vehicle: VehicleViewModel { return _vehicle.viewModel() }
    var hashValue: Int { return _arrival.hashValue }
    var description: String {
        return "ArrivalViewModel(route: \(self._route), vehicle: \(self._vehicle), station: \(self._arrival.station))"
    }
    var time: NSDate { return _arrival.time }
    
    init(_ arrival: Arrival) {
        _arrival = arrival
        _route = arrival.trip.route
        _vehicle = arrival.trip.vehicle
        
        let arrived = arrival.isVehicleAtStation()
        self.isInTransit = !arrived
        self.hasArrived = arrived
    }
    
    func relativeArrivalTime() -> String {
        let relativeArrival = _arrival.time.timeIntervalSinceNow
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
    
    // MARK: State transitions
    
    func withAdvancedStation() -> ArrivalViewModel {
        return ArrivalViewModel(_arrival.withAdvancedStation())
    }
    
    // MARK: Static functions
    
    // Sort by arrival time
    static func compareTimes(a: ArrivalViewModel, isOrderedBefore b: ArrivalViewModel) -> Bool {
        return a.time.compare(b.time) != .OrderedDescending
    }
}

func ==(a: ArrivalViewModel, b: ArrivalViewModel) -> Bool {
    return a._arrival == b._arrival
}