//
//  VehicleViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

class VehicleViewModel: NSObject, MKAnnotation {
    private var _vehicle: Vehicle
    
    var name: String { return _vehicle.name }
    var id: String { return _vehicle.id }
    var location: (latitude: Double, longitude: Double) { return _vehicle.location }
    var capacity: Double { return _vehicle.capacity }
    
    var coordinate: CLLocationCoordinate2D
    
    init(_ vehicle: Vehicle) {
        _vehicle = vehicle
        self.coordinate = CLLocationCoordinate2DMake(_vehicle.location.latitude, _vehicle.location.longitude)
    }
}
