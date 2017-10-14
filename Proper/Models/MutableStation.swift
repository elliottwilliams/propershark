//
//  MutableStation.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Argo
import MapKit

class MutableStation: NSObject, MutableModel, Comparable {
  typealias FromModel = Station
  typealias RouteType = MutableRoute
  typealias VehicleType = MutableVehicle

  // MARK: Interal Properties
  internal let connection: ConnectionType
  private static let retryAttempts = 3

  // MARK: Station Support
  var identifier: FromModel.Identifier { return self.stopCode }
  var topic: String { return FromModel.topic(for: self.identifier) }

  // MARK: Station Attributes
  let stopCode: FromModel.Identifier
  var name: MutableProperty<String?> = .init(nil)
  var stationDescription: MutableProperty<String?> = .init(nil)
  var position: MutableProperty<Point?> = .init(nil)
  var routes: MutableProperty<Set<RouteType>> = .init(Set())
  var vehicles: MutableProperty<Set<VehicleType>> = .init(Set())

  lazy var sortedVehicles: Property<[VehicleType]> = {
    return Property(initial: [], then: self.vehicles.producer.map { $0.sorted() })
  }()

  // MARK: Signal Producer
  lazy var producer: SignalProducer<TopicEvent, ProperError> = {
    let now = self.connection.call("meta.last_event", with: [self.topic, self.topic])
    let future = self.connection.subscribe(to: self.topic)
    return SignalProducer<SignalProducer<TopicEvent, ProperError>, ProperError>([now, future])
      .flatten(.merge)
      .logEvents(identifier: "MutableStation.producer", logger: logSignalEvent)
      .attempt(operation: self.handle)
  }()

  required init(from station: Station, connection: ConnectionType) throws {
    self.stopCode = station.stopCode
    self.connection = connection
    super.init()
    try apply(station)
  }

  func handle(event: TopicEvent) -> Result<(), ProperError> {
    if let error = event.error {
      return .failure(.decodeFailure(error))
    }

    return ProperError.capture({
      switch event {
      case .station(.update(let station, _)):
        try self.apply(station.value!)
      default: break
      }
    })
  }

  func apply(_ station: Station) throws {
    if station.identifier != self.identifier {
      throw ProperError.applyFailure(from: station.identifier, onto: self.identifier)
    }

    self.name <- station.name
    self.stationDescription <- station.description
    self.position <- station.position

    try attachOrApplyChanges(to: self.routes, from: station.routes)
    try attachOrApplyChanges(to: self.vehicles, from: station.vehicles)
  }

  func snapshot() -> FromModel {
    return Station(stopCode: stopCode, name: name.value, description: stationDescription.value, position: position.value,
                   routes: routes.value.map({ $0.snapshot() }),
                   vehicles: vehicles.value.map({ $0.snapshot() }))
  }


  // MARK: Nested Types
  class Annotation: NSObject, MKAnnotation {
    @objc var coordinate: CLLocationCoordinate2D
    @objc var title: String?
    @objc var subtitle: String?

    private let disposable = ScopedDisposable(CompositeDisposable())

    /// Create an annotation for the given station, at a given point (which is passed independently since we can't
    /// always ensure that a MutableStation has a `position`)
    init(from station: MutableStation, at point: Point) {
      // Establish starting coordinates
      self.coordinate = CLLocationCoordinate2D(point: point)
      super.init()

      // Bind current and future values of the station to annotation properties
      disposable.inner += station.position.producer.startWithValues { point in
        if let point = point {
          self.coordinate = CLLocationCoordinate2D(point: point)
        }
      }
      disposable.inner += station.name.producer.startWithValues { self.title = $0 }
      disposable.inner += station.stationDescription.producer.startWithValues { self.subtitle = $0 }
    }
  }
}

func < (a: MutableStation, b: MutableStation) -> Bool {
  return a.identifier < b.identifier
}

extension Collection where Iterator.Element: MutableStation {
  /// Order by geographic distance from `point`, ascending. Stations in the collection without a defined position will
  /// appear at the end of the ordering.
  func sortDistanceTo(point: Point) -> [Generator.Element] {
    return self.sorted(by: { a, b in
      // Stations with undefined positions should float to the end.
      guard let aPosition = a.position.value else { return false }
      guard let bPosition = b.position.value else { return true }

      let loc = CLLocation(point: point)
      return loc.distance(from: CLLocation(point: aPosition)) <
        loc.distance(from: CLLocation(point: bPosition))
    })
  }
}

extension MutableStation: MKAnnotation {
  var coordinate: CLLocationCoordinate2D {
    guard let position = self.position.value else {
      return kCLLocationCoordinate2DInvalid
    }
    return CLLocationCoordinate2D(point: position)
  }

  var title: String? { return name.value }
  var subtitle: String? { return stationDescription.value }
}
