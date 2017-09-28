//
//  CitybusConfig.swift
//  Proper
//
//  Created by Elliott Williams on 9/19/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import MapKit
import ReactiveSwift

struct CitybusConfig: ConfigProtocol {
  static let id = "citybus"

  let agency = CitybusAgencyConfig() as AgencyConfig
  let app = SharedAppConfig() as AppConfig
  let connection = CitybusConnectionConfig() as ConnectionConfig
  let logging = SharedLoggingConfig() as LoggingConfig
  let ui = CitybusUIConfig() as UIConfig
}

struct CitybusAgencyConfig: AgencyConfig {
  let key = "citybus"
  let name = "CityBus"
  let region = MKCoordinateRegionMakeWithDistance(
    CLLocationCoordinate2D(latitude: 40.4088972, longitude: -86.927739), 9200, 1264)
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

struct CitybusConnectionConfig: ConnectionConfig {
  let server = URL(string: "ws://irene.local:32771/ws")!
  let realm = "realm1"
  let scheduleService = "timetable" 
}

struct CitybusUIConfig: UIConfig {
  let defaultBadgeColor = UIColor.gray
}
