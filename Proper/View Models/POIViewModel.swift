//
//  POIViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveSwift
import Curry
import Result
import Dwifft

class POIViewModel {
  typealias Distance = CLLocationDistance
  typealias NamedPoint = (point: Point, name: String, isDeviceLocation: Bool)

  // TODO - Maybe raise the search radius but cap the number of results returned?
  static let defaultSearchRadius = Distance(250) // in meters
  static let arrivalRowHeight = CGFloat(44)
  static let distanceFormatter = MKDistanceFormatter()

  static func distanceString(_ producer: SignalProducer<(Point, Point), NoError>) ->
    SignalProducer<String, NoError>
  {
    return producer.map({ $0.distance(from: $1) })
      .map({ self.distanceFormatter.string(fromDistance: $0) })
  }

  static func distinctLocations(_ producer: SignalProducer<CLLocation, ProperError>) ->
    SignalProducer<NamedPoint, ProperError>
  {
    return producer.map({ $0.coordinate })
      .combinePrevious(kCLLocationCoordinate2DInvalid)
      .filter({ prev, next in
        return prev.latitude != next.latitude || prev.longitude != next.longitude })
      .map({ _, next in
        NamedPoint(point: Point(coordinate: next), name: "Current Location", isDeviceLocation: true) })
      .logEvents(identifier: "POIViewController.deviceLocation", logger: logSignalEvent)
  }
}
