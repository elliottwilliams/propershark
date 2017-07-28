//
//  MKCoordinateRegion.swift
//  Proper
//
//  Created by Elliott Williams on 7/28/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit

extension MKCoordinateRegion: Equatable {
  public static func == (a: MKCoordinateRegion, b: MKCoordinateRegion) -> Bool {
    return a.center == b.center && a.span == b.span
  }
}

extension MKCoordinateRegion {
  public static func * (coordinate: MKCoordinateRegion, scale: Double) -> MKCoordinateRegion {
    return MKCoordinateRegion(center: coordinate.center, span: coordinate.span * scale)
  }
}
