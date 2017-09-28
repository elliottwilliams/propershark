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

  static var id: String { get }
  static func make() -> Self
  init()
}

protocol AgencyConfig {
  var key: String { get }
  var name: String { get }
  var region: MKCoordinateRegion { get }
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
}

protocol LoggingConfig {
  var ignoreSignalProducers: Set<String> { get }
  var logJSON: Bool { get }
}

protocol UIConfig {
  var defaultBadgeColor: UIColor { get }
}

extension ConfigProtocol {
  static func make() -> Self { return Self() }
}