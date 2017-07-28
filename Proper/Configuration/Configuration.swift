//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import ReactiveSwift

struct Config {
  struct agency {
    static let key = "bart"
    static let name = "BART"
    static let region = MKCoordinateRegionMakeWithDistance(
      CLLocationCoordinate2D(latitude: 37.784128, longitude: -122.4570273), 33_000, 20_000)
    static let timeResolution = TimeInterval(30)

    static let badgeForRoute: (MutableRoute) -> Property<String?> = { _ in .init(value: nil) }
    static let titleForRoute: (MutableRoute) -> Property<String?> = { .init($0.name) }
    static let titleForArrival: (Arrival) -> Property<String?> = { arrival in
      if let heading = arrival.heading {
        return Property(value: heading)
      } else {
        return Property(arrival.route.name)
      }
    }
  }

  struct app {
    static let key = "proper"
    static let name = "Proper Shark"
  }

  struct connection {
    static let server = URL(string: "ws://Irene.local:8080/ws")!
    static let realm = "realm1"
  }

  struct logging {
    static let ignoreSignalProducers = Set([
      "MDWamp.subscribeWithSignal",
      "MDWamp.callWithSignal",
      "Connection.connectionProducer",
      "Connection.subscribe",
      "MutableRoute.producer"
    ])
    static let logJSON = false
  }

  struct ui {
    static let defaultBadgeColor = UIColor.gray
  }
}
