//
//  TripViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct TripViewModel {
    
    let _trip: Trip
    let vehicle: VehicleViewModel
    let route: RouteViewModel
    let stations: [StationViewModel]
    
    var currentStation: StationViewModel {
        return stations[_trip.currentStation]
    }
    
    init(_ trip: Trip) {
        _trip = trip
        vehicle = _trip.vehicle.viewModel()
        route = _trip.route.viewModel()
        stations = _trip.route.stations.map { $0.viewModel() }
    }
    
    func isVehicleAtCurrentStation() -> Bool {
        return _trip.isVehicleAtCurrentStation()
    }
    
    func withNextStationSelected() -> TripViewModel {
        return TripViewModel(_trip.withNextStationSelected())
    }
}

func ==(a: TripViewModel, b: TripViewModel) -> Bool {
    return a._trip.vehicle == b._trip.vehicle && a._trip.route == b._trip.route
}
