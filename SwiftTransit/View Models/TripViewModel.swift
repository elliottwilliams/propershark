//
//  TripViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

class TripViewModel: NSObject {
    
    let _trip: Trip
    let _vehicle: VehicleViewModel
    let _route: RouteViewModel
    let _stations: [StationViewModel]
    
    var currentStation: StationViewModel {
        return _stations[_trip.currentStation]
    }
    
    init(_ trip: Trip) {
        _trip = trip
        _vehicle = _trip.vehicle.viewModel()
        _route = _trip.route.viewModel()
        _stations = _trip.route.stations.map { $0.viewModel() }
    }
    
    func isVehicleAtCurrentStation() -> Bool {
        return _trip.isVehicleAtCurrentStation()
    }
}

func ==(a: TripViewModel, b: TripViewModel) -> Bool {
    return a._trip.vehicle == b._trip.vehicle && a._trip.route == b._trip.route
}
