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
    let annotationKey: String

    init?(station: MutableStation, annotationKey: String) {
        guard let position = station.position.value else {
            return nil
        }
        self.station = station
        self.position = position
        self.annotationKey = annotationKey
    }

    var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(point: position) }
    var title: String? { return annotationKey }
    var subtitle: String? { return station.name.value }
}
