//
//  BartConfig.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit
import ReactiveSwift

struct BartConfig: ConfigProtocol {
  static let id = "bart"

  let agency = BartAgencyConfig() as AgencyConfig
  let app = SharedAppConfig() as AppConfig
  let connection = BartConnectionConfig() as ConnectionConfig
  let logging = SharedLoggingConfig() as LoggingConfig
  let ui = BartUIConfig() as UIConfig
}

struct BartAgencyConfig: AgencyConfig {
  let key = "bart"
  let name = "BART"
  let region = MKCoordinateRegionMakeWithDistance(
    CLLocationCoordinate2D(latitude: 37.784128, longitude: -122.4570273), 33_000, 20_000)
  let timeResolution = TimeInterval(30)

  let badgeForRoute: (MutableRoute) -> Property<String?> = { _ in .init(value: nil) }
  let titleForRoute: (MutableRoute) -> Property<String?> = { .init($0.name) }
  let titleForArrival: (Arrival) -> Property<String?> = { arrival in
    if let heading = arrival.heading {
      return Property(value: heading)
    } else {
      return Property(arrival.route.name)
    }
  }
}

struct BartConnectionConfig: ConnectionConfig {
  let server = URL(string: "ws://irene.local:32772/ws")!
  let realm = "realm1"
  let scheduleService = "providence"
}

struct BartUIConfig: UIConfig {
  let defaultBadgeColor = UIColor.gray
}
