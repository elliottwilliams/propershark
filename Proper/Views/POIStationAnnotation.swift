//
//  POIStationAnnotation.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

class POIStationAnnotation: NSObject, MKAnnotation {
    let station: MutableStation
    let stationPosition: Point
    let badge: StationBadge
    let point: Point
    let distanceFormatter = MKDistanceFormatter()

    init?(station: MutableStation, badge: StationBadge, fromPoint point: Point) {
        guard let position = station.position.value else {
            return nil
        }
        self.station = station
        self.stationPosition = position
        self.badge = badge
        self.point = point
    }

    var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(point: stationPosition) }
    var title: String? { return station.name.value }
    var subtitle: String? { return "\(distanceString) away" }
    var distance: CLLocationDistance {
        return CLLocation(point: stationPosition).distanceFromLocation(CLLocation(point: point))
    }
    var distanceString: String {
        return distanceFormatter.stringFromDistance(distance)
    }
}
