//
//  MKCircle.swift
//  Proper
//
//  Created by Elliott Williams on 3/19/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit

extension MKCircle {
  func contains(coordinate other: CLLocationCoordinate2D) -> Bool {
    let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    let point = CLLocation(latitude: other.latitude, longitude: other.longitude)
    return origin.distance(from: point) <= radius
  }
}
