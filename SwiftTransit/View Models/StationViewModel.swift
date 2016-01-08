//
//  StationViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct StationViewModel: Hashable {
    
    // MARK: Properties
    var coordinate: CLLocationCoordinate2D
    var _station: Station
    
    // MARK: Computed properties
    var name: String { return _station.name }
    var id: String { return _station.id }
    var neighborhood: [String]? { return _station.neighborhood }
    var location: (latitude: Double, longitude: Double) { return _station.location }
    var hashValue: Int { return _station.hashValue }
    
    init(_ station: Station) {
        _station = station
        self.coordinate = CLLocationCoordinate2DMake(_station.location.latitude, _station.location.longitude)
    }
    
    func arrivalsAtStation() -> [ArrivalViewModel] {
        let trips = Trip.DemoTrips.filter() { $0.route.stations.filter() { $0.id == _station.id }.count > 0 }
        return [Arrival.demoArrivalForTripAndStation(trips.first!, station: _station)].map { ArrivalViewModel($0) }
    }
    
    func tripsCurrentlyAtStation() -> [TripViewModel] {
        let trips = Trip.DemoTrips.filter { $0.viewModel().currentStation == self }
        return trips.map { $0.viewModel() }
    }
    
    func mapAnnotation() -> StationMapAnnotation {
        return StationMapAnnotation(loc: self.location)
    }
}

func ==(a: StationViewModel, b: StationViewModel) -> Bool {
    return a._station == b._station
}

class StationMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(loc: (Double, Double)) {
        self.coordinate = CLLocationCoordinate2DMake(loc.0, loc.1)
    }
}