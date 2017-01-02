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
    let position: Point
    let badge: StationBadge

    init?(station: MutableStation, badge: StationBadge) {
        guard let position = station.position.value else {
            return nil
        }
        self.station = station
        self.position = position
        self.badge = badge
    }

    var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(point: position) }
    var title: String? { return badge.name }
    var subtitle: String? { return station.name.value }
}
