//
//  TripViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct TripViewModel: Hashable, CustomStringConvertible {
    
    let _trip: Trip
    let vehicle: VehicleViewModel
    let route: RouteViewModel
    let stations: [StationViewModel]
    
    var hashValue: Int { return _trip.hashValue }
    var description: String {
        return "TripViewModel(\(self._trip))"
    }
    
    init(_ trip: Trip) {
        _trip = trip
        vehicle = _trip.vehicle.viewModel()
        route = _trip.route.viewModel()
        stations = _trip.route.stations.map { $0.viewModel() }
    }
    
    @available(*, deprecated=1.0)
    func isVehicleAtCurrentStation() -> Bool {
        return _trip.isVehicleAtCurrentStation()
    }
    
    @available(*, deprecated=1.0)
    func withNextStationSelected() -> TripViewModel {
        return TripViewModel(_trip.withNextStationSelected())
    }
    
    @available(*, deprecated=1.0)
    func currentStation() -> StationViewModel {
        let inTransit = !isVehicleAtCurrentStation()
        return stations[_trip.currentStation].withIsInTransit(inTransit)
    }
}

func ==(a: TripViewModel, b: TripViewModel) -> Bool {
    return a._trip.vehicle == b._trip.vehicle && a._trip.route == b._trip.route
}
