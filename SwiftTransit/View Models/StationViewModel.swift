//
//  StationViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

class StationViewModel: NSObject, MKAnnotation {
    private var _station: Station
    
    var name: String { return _station.name }
    
    var coordinate: CLLocationCoordinate2D
    
    init(_ station: Station) {
        _station = station
        self.coordinate = CLLocationCoordinate2DMake(_station.location.latitude, _station.location.longitude)
    }
    
    func arrivalsAtStation() -> [ArrivalViewModel] {
        let trips = Trip.DemoTrips.filter() { $0.route.stations.filter() { $0.id == _station.id }.count > 0 }
        return [Arrival.demoArrivalForTripAndStation(trips.first!, station: _station)].map { ArrivalViewModel($0) }
    }
}