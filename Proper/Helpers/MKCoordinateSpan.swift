//
//  MKCoordinateSpan.swift
//  Proper
//
//  Created by Elliott Williams on 7/28/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit

extension MKCoordinateSpan: Equatable {
  public static func == (a: MKCoordinateSpan, b: MKCoordinateSpan) -> Bool {
    return a.latitudeDelta == b.latitudeDelta && a.longitudeDelta == b.longitudeDelta
  }
}

extension MKCoordinateSpan {
  public static func * (span: MKCoordinateSpan, scale: Double) -> MKCoordinateSpan {
    return MKCoordinateSpan(latitudeDelta: span.longitudeDelta * scale,
                            longitudeDelta: span.latitudeDelta * scale)
  }
}
