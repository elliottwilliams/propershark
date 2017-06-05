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

struct NearbyStationsViewModel: SignalChain {
  typealias Input = (Point, SearchRadius)
  typealias Output = [MutableStation]

  // TODO - Swift 3 brings generic type aliases, which means we can do something nice like:
  // typealias SP<U> = SignalProducer<U, ProperError>
  typealias SearchRadius = CLLocationDistance
  typealias CenterPoint = CLLocationCoordinate2D
  typealias Distance = CLLocationDistance

  static func searchArea(producer: SignalProducer<(Point, SearchRadius), ProperError>) ->
    SignalProducer<MKMapRect, ProperError>
  {
    return producer.map({ point, radius -> MKMapRect in
      let circle = MKCircle(center: CLLocationCoordinate2D(point: point), radius: radius)
      return circle.boundingMapRect
    })
  }

  static func getStations(connection: ConnectionType) -> SignalProducer<[Station], ProperError> {
    return connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
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

  static func chain(connection: ConnectionType, producer: SignalProducer<(Point, SearchRadius), ProperError>) ->
    SignalProducer<[MutableStation], ProperError>
  {
    let producer = SignalProducer.combineLatest(getStations(connection: connection),
                                                producer |> searchArea)
      |> curry(filterNearby)(connection)
    return producer.logEvents(identifier: "NearbyStationsViewModel.chain", logger: logSignalEvent)
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
