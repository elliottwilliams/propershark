//
//  NearbyStationsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 3/18/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Curry
import CoreLocation
import MapKit

struct NearbyStationsViewModel {
  // TODO - Swift 3 brings generic type aliases, which means we can do something nice like:
  // typealias SP<U> = SignalProducer<U, ProperError>
  typealias SearchRadius = MKCoordinateSpan
  typealias CenterPoint = CLLocationCoordinate2D
  typealias Distance = CLLocationDistance

  static func searchArea(givenBy producer: SignalProducer<(Point, SearchRadius), NoError>) ->
    SignalProducer<MKMapRect, NoError>
  {
    return producer.map({ point, radius -> MKMapRect in
      let region = MKCoordinateRegion(center: CLLocationCoordinate2D(point: point), span: radius)
      // Build a MKMapRect by determining the "corners" of the coordinate region.
      let topRight =
        MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: region.center.latitude + region.span.latitudeDelta / 2,
                                                       longitude: region.center.longitude - region.span.longitudeDelta / 2))
      let bottomLeft =
        MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: region.center.latitude - region.span.latitudeDelta / 2,
                                                       longitude: region.center.longitude + region.span.longitudeDelta / 2))
      let size = MKMapSize(width: abs(topRight.x - bottomLeft.x),
                           height: abs(topRight.y - bottomLeft.y))
      let origin = MKMapPoint(x: min(topRight.x, bottomLeft.x),
                              y: min(topRight.y, bottomLeft.y))
      return MKMapRect(origin: origin, size: size)

    })
  }

  static func getStations(connection: ConnectionType, scheduler: Scheduler) -> SignalProducer<[Station], ProperError> {
    return connection.call("agency.stations").observe(on: scheduler).attemptMap({ event -> Result<[AnyObject], ProperError> in
      // Received events should be Agency.stations events, which contain a list of all stations on the agency.
      if case .agency(.stations(let stations)) = event {
        return .success(stations)
      } else {
        return .failure(ProperError.eventParseFailure)
      }
    }).decodeAnyAs(Station.self)
  }

  static func filterNearby(connection: ConnectionType, producer: SignalProducer<([Station], MKMapRect), ProperError>) ->
    SignalProducer<[MutableStation], ProperError>
  {

    return producer.map({ stations, rect -> ([Station], CenterPoint) in
      // Filter down to a set of stations which have a defined position that is inside `circle`.
      let nearby = stations.filter({ $0.position.map({ MKMapRectContainsPoint(rect, MKMapPoint(point: $0)) }) == true })
      let center = MKCoordinateRegionForMapRect(rect).center
      return (nearby, center)
    }).attemptMap({ stations, center -> Result<[MutableStation], ProperError> in
      // Attempt to create MutableStations out of all stations.
      let mutables = stations.map({ MutableStation.create(from: $0, connection: connection) })
      if let error = mutables.filter({ $0.error != nil }).first?.error {
        return .failure(error)
      }

      let centerPoint = Point(coordinate: center)
      let sorted = mutables.flatMap({ result in
        // Ignore stations without a known position.
        result.value.map({ st in st.position.value.map({ pos in (st, pos) }) }) ?? nil
      }).sorted(by: { a, b in
        let ((_, apos), (_, bpos)) = (a, b)
        return apos.distance(from: centerPoint) < bpos.distance(from: centerPoint)
      }).map({ st, pos in st })
      return .success(sorted)
    })
  }

  static func makeMutables(connection: ConnectionType) -> (SignalProducer<[Station], ProperError>) ->
    SignalProducer<[MutableStation], ProperError>
  {
    return { producer in
      producer.attemptMap({ stations in
        ProperError.capture({
          try stations.map({ station in try MutableStation(from: station, connection: connection) })
        })
      })
    }
  }

  static func sorted(fromDistanceTo point: Point) -> (SignalProducer<[MutableStation], ProperError>) ->
    SignalProducer<[MutableStation], ProperError>
  {
    return { producer in
      return producer.map({ stations in
        stations.sortDistanceTo(point: point)
      })
    }
  }

  static func orderedList(producer: SignalProducer<[MutableStation: Distance], ProperError>) ->
    SignalProducer<[(MutableStation, Distance)], ProperError>
  {
    return producer.map({ dict in
      dict.sorted(by: { a, b in
        let (_, ad) = a, (_, bd) = b
        return ad < bd
      })
    })
  }

  static func log(producer: SignalProducer<[MutableStation], ProperError>) -> SignalProducer<[MutableStation], ProperError> {
    return producer.logEvents(identifier: "NearbyStationsViewModel.search", logger: logSignalEvent)
  }

  static func search(config: ConfigSP, searchParameters params: SignalProducer<Point, NoError>) ->
    SignalProducer<[MutableStation], ProperError>
  {
    let worker = QueueScheduler(qos: .userInitiated, name: "NearbyStationsViewModel worker")
    return config
      .start(on: worker)
      .flatMap(.latest, transform: { Connection.makeFromConfig(connectionConfig: $0.connection) })
      .combineLatest(with: params.promoteErrors(ProperError.self))
      .flatMap(.latest, transform: { connection, point in
        return getStations(connection: connection, scheduler: worker)
          |> makeMutables(connection: connection)
          |> sorted(fromDistanceTo: point)
          |> log
      })
  }
}


/// Returns the station-distance pair of smaller distance.
func < (a: (MutableStation, CLLocationDistance), b: (MutableStation, CLLocationDistance)) -> Bool {
  let ((_, ad), (_, bd)) = (a, b)
  return ad < bd
}

func == (a: (MutableStation, CLLocationDistance), b: (MutableStation, CLLocationDistance)) -> Bool {
  let ((ast, adi), (bst, bdi)) = (a, b)
  return ast == bst && adi == bdi
}
