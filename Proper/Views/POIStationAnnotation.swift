//
//  POIStationAnnotation.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import MapKit

class POIStationAnnotation: NSObject, MKAnnotation {
    let station: MutableStation
    let stationPosition: Point
    let badge: StationBadge
    let distance: AnyProperty<String?>

    init?(station: MutableStation, badge: StationBadge, distance: AnyProperty<String?>) {
        guard let position = station.position.value else {
            return nil
        }
        self.station = station
        self.stationPosition = position
        self.badge = badge
        self.distance = distance
    }

    var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(point: stationPosition) }
    var title: String? { return station.name.value }
    var subtitle: String? { return distance.value.map({ "\($0) away" }) }
}
