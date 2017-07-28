//
//  CLLocationCoordinate2D.swift
//  Proper
//
//  Created by Elliott Williams on 7/28/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit

extension CLLocationCoordinate2D: Equatable {
  public static func == (a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
    return a.latitude == b.latitude && a.longitude == b.longitude
  }
}
