//
//  ConfigProtocols.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveSwift

protocol ConfigProtocol {
  var agency: AgencyConfig { get }
  var app: AppConfig { get }
  var connection: ConnectionConfig { get }
  var logging: LoggingConfig { get }
  var ui: UIConfig { get }
  var id: String { get }

  static var id: String { get }
  static func make() -> Self
  init()
}

protocol AgencyConfig {
  var key: String { get }
  var name: String { get }
  var region: MKCoordinateRegion { get }
  var maxLatitudeSpanForStations: CLLocationDegrees { get }
  var timeResolution: TimeInterval { get }
  var badgeForRoute: (MutableRoute) -> Property<String?> { get }
  var titleForRoute: (MutableRoute) -> Property<String?> { get }
  var titleForArrival: (Arrival) -> Property<String?> { get }
}

protocol AppConfig {
  var key: String { get }
  var name: String { get }
}

protocol ConnectionConfig {
  var server: URL { get }
  var realm: String { get }
  var scheduleService: String { get }
  var hashed: AnyHashable { get }
  func makeConnection() -> ConnectionSP
}

protocol LoggingConfig {
  var ignoreSignalProducers: Set<String> { get }
  var logJSON: Bool { get }
}

protocol UIConfig {
  var defaultBadgeColor: UIColor { get }
}

extension ConfigProtocol {
  var id: String { return Self.id }
  static func make() -> Self { return Self() }
}

extension ConnectionConfig {
  var hashed: AnyHashable { return server.hashValue ^ realm.hashValue ^ scheduleService.hashValue }
  func makeConnection() -> ConnectionSP {
    return Connection.makeFromConfig(connectionConfig: self)
  }
}
