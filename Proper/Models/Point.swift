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

    func distanceFrom(point: Point) -> CLLocationDistance {
        return CLLocation(point: point).distanceFromLocation(CLLocation(point: self))
    }
}

func ==(a: Point, b: Point) -> Bool {
    return a.lat == b.lat && a.long == b.long
}

extension Point: Decodable {
    static func decode(json: JSON) -> Decoded<Point> {
        switch json {
        case .Array(_):
            return curry(Point.init(list:))
                <^> decodeArray(json)
            
        case .Object(_):
            return curry(Point.init(lat:long:))
                <^> json <| "latitude"
                <*> json <| "longitude"
        default:
            return .Failure(.TypeMismatch(expected: "array of coordinates or dictionary", actual: "something else"))
        }
    }
}

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
        self.init(x: point.lat, y: point.long)
    }
}
