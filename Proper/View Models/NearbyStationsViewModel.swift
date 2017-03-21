//
//  NearbyStationsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 3/18/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import Curry

struct NearbyStationsViewModel: SignalChain {
    typealias Input = (Point, SearchRadius)
    typealias Output = [MutableStation: Distance]

    // TODO - Swift 3 brings generic type aliases, which means we can do something nice like:
    // typealias SP<U> = SignalProducer<U, ProperError>
    typealias SearchRadius = CLLocationDistance
    typealias CenterPoint = CLLocationCoordinate2D
    typealias Distance = CLLocationDistance

    static func searchArea(producer: SignalProducer<(Point, SearchRadius), ProperError>) ->
        SignalProducer<MKMapRect, ProperError>
    {
        return producer.map({ point, radius -> MKMapRect in
            let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(point: point), radius: radius)
            return circle.boundingMapRect
        })
    }

    static func getStations(connection: ConnectionType) -> SignalProducer<[Station], ProperError> {
        return connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
            // Received events should be Agency.stations events, which contain a list of all stations on the agency.
            if case .Agency(.stations(let stations)) = event {
                return .Success(stations)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).decodeAnyAs(Station.self)
    }

    static func filterNearby(connection: ConnectionType, producer: SignalProducer<([Station], MKMapRect), ProperError>) ->
        SignalProducer<[MutableStation: Distance], ProperError>
    {

        return producer.map({ stations, rect -> ([Station], CenterPoint) in
            // Filter down to a set of stations which have a defined position that is inside `circle`.
            let nearby = stations.filter({ $0.position.map({ MKMapRectContainsPoint(rect, MKMapPoint(point: $0)) }) == true })
            let center = MKCoordinateRegionForMapRect(rect).center
            return (nearby, center)
        }).attemptMap({ stations, center -> Result<[MutableStation: Distance], ProperError> in
            // Attempt to create MutableStations out of all stations.
            let mutables = stations.map({ MutableStation.create($0, connection: connection) })
            if let error = mutables.filter({ $0.error != nil }).first?.error {
                return .Failure(error)
            }

            // Filter out stations without a known position.
            let m: [(MutableStation, Point)] = mutables.flatMap({ $0.value }).flatMap({ station in
                if let position = station.position.value {
                    return (station, position)
                } else {
                    return nil
                }
            })

            // Compute each station's distance from location, and send.
            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
            var distances = [MutableStation: Distance]()

            for (station, position) in m {
                let distance = location.distanceFromLocation(CLLocation(point: position))
                distances[station] = distance
            }
            
            return .Success(distances)
        })
    }

    static func orderedList(producer: SignalProducer<[MutableStation: Distance], ProperError>) ->
        SignalProducer<[(MutableStation, Distance)], ProperError>
    {
        return producer.map({ dict in
            dict.sort({ a, b in
                let (_, ad) = a, (_, bd) = b
                return ad < bd
            })
        })
    }

    static func chain(connection: ConnectionType, producer: SignalProducer<(Point, SearchRadius), ProperError>) ->
        SignalProducer<[MutableStation: CLLocationDistance], ProperError>
    {
        let producer = combineLatest(getStations(connection), producer |> searchArea) |> curry(filterNearby)(connection)
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
