//
//  POIStationAnnotation.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import MapKit

class POIStationAnnotation: NSObject, MKAnnotation {
  let station: MutableStation
  let stationPosition: Point
  let distance: Property<String?>

  init(station: MutableStation, locatedAt position: Point, distance: SignalProducer<String, NoError>)
  {
    self.station = station
    self.stationPosition = position
    self.distance = Property(initial: nil, then: distance.map(Optional.init))
  }

  var coordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(point: stationPosition) }
  var title: String? { return station.name.value }
  var subtitle: String? { return distance.value.map({ "\($0) away" }) }
}
