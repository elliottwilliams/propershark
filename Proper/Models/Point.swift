//
//  Point.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry
import CoreLocation
import MapKit
import Runes

struct Point: Equatable {
  let lat: Double
  let long: Double

  init(list: [Double]) {
    self.lat = list[0]
    self.long = list[1]
  }

  init(lat: Double, long: Double) {
    self.lat = lat
    self.long = long
  }

  init(coordinate: CLLocationCoordinate2D) {
    self.lat = coordinate.latitude
    self.long = coordinate.longitude
  }

  func distance(from point: Point) -> CLLocationDistance {
    return CLLocation(point: point).distance(from: CLLocation(point: self))
  }
}

func ==(a: Point, b: Point) -> Bool {
  return a.lat == b.lat && a.long == b.long
}

extension Point: Argo.Decodable {
  static func decode(_ json: JSON) -> Decoded<Point> {
    switch json {
    case .array(_):
      return curry(Point.init(list:))
        <^> decodeArray(json)

    case .object(_):
      return curry(Point.init(lat:long:))
        <^> json <| "latitude"
        <*> json <| "longitude"
    default:
      return .failure(.typeMismatch(expected: "array of coordinates or dictionary", actual: "something else"))
    }
  }
}

// MARK: Type conversion

extension CLLocation {
  convenience init(point: Point) {
    self.init(latitude: point.lat, longitude: point.long)
  }
}

extension CLLocationCoordinate2D {
  init(point: Point) {
    self.init(latitude: point.lat, longitude: point.long)
  }
}

extension MKMapPoint {
  init(point: Point) {
    self = MKMapPointForCoordinate(CLLocationCoordinate2D(point: point))
  }
}
