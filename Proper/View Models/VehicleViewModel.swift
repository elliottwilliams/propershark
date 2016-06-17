//
//  VehicleViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct VehicleViewModel: Hashable, CustomStringConvertible {
    let _vehicle: Vehicle
    
    var name: String { return _vehicle.name }
    var id: String { return _vehicle.id }
    var location: (latitude: Double, longitude: Double) { return _vehicle.location }
    var capacity: Double { return _vehicle.capacity }
    
    var hashValue: Int { return _vehicle.hashValue }
    var description: String {
        return "VehicleViewModel(\(self._vehicle))"
    }
    
    init(_ vehicle: Vehicle) {
        _vehicle = vehicle
    }
    
    func mapAnnotation() -> VehicleMapAnnotation {
        return VehicleMapAnnotation(coords: self.location)
    }
}

func ==(a: VehicleViewModel, b: VehicleViewModel) -> Bool {
    return a.id == b.id
}

class VehicleMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(coords: (_: Double, _: Double)) {
        self.coordinate = CLLocationCoordinate2DMake(coords.0, coords.1)
    }
}