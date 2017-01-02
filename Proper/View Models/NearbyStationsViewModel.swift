//
//  NearbyStationsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import Dwifft

class NearbyStationsViewModel: NSObject, UITableViewDataSource, MutableModelDelegate {

    // TODO - Maybe raise the search radius but cap the number of results returned?
    static let searchRadius = CLLocationDistance(250) // in meters
    static let arrivalRowHeight = CGFloat(44)
    static let stationRowHeight = CGFloat(55)

    /**
     The geographic point to base nearby stations on. Changes to this property flow through the list of nearby stations
     emitted by `stations`.

     Performance note: When `point` changes, the entire list will be reloaded, which causes an expensive RPC to
     `agency.stations`. Because of this, be judicious about modifying `point`.
     */
    let point: AnyProperty<Point>

    internal let connection: ConnectionType
    internal let disposable = CompositeDisposable()

    let stations: MutableProperty<[MutableStation]> = .init([])
    lazy var letteredStations: AnyProperty<[(String, MutableStation)]> = {
        return AnyProperty(initialValue: [], producer: self.stations.producer |> self.assignLetterings)
    }()

    lazy var producer: SignalProducer<[MutableStation], ProperError> = { [unowned self] in
        // TODO: Consider adding a threshold to `point`s value, so that only significant changes in point reload the
        // stations.
        return self.point.producer.flatMap(.Latest, transform: { point -> SignalProducer<[MutableStation], ProperError> in
            // Compose: a search region for `point`, with a producer of static stations in that region, with a set of
            // MutableStations corresponding
            let stations = NearbyStationsViewModel.searchArea(for: point) |> self.produceStations |> self.produceMutables
            // Sort the set by distance to `point` and assign letters to the stations.
            return stations.map({ $0.sortDistanceTo(point) })
        })
    }()

    init<P: PropertyType where P.Value == Point>(point: P, connection: ConnectionType = Connection.cachedInstance) {
        self.point = AnyProperty(point)
        self.connection = connection
    }

    /**
     Returns a signal producer that emits stations inside the given MKMapRect.

     Implementation note: The signal producer returned calls `agency.stations`, which returns *all* stations for the
     agency and is thus very slow.
     */
    func produceStations(within circle: MKCircle) -> SignalProducer<Set<Station>, ProperError> {
        return connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
            // Received events should be Agency.stations events, which contain a list of all stations on the agency.
            if case .Agency(.stations(let stations)) = event {
                return .Success(stations)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).decodeAnyAs(Station.self).map({ stations in
            // Filter down to a set of stations which have a defined position that is inside `circle`.
            Set(stations.filter({ $0.position.map({ circle.contains(coordinate: CLLocationCoordinate2D(point: $0)) }) == true }))
        })
    }

    /**
     Given a producer of (static) station models, attaches and maintains MutableStations out of the latest set of
     static models.
     */
    func produceMutables(producer: SignalProducer<Set<Station>, ProperError>) -> SignalProducer<Set<MutableStation>, ProperError> {
        return producer.attemptMap({ stations -> Result<Set<MutableStation>, ProperError> in

            // Attempt to create MutableStations out of all stations.
            do {
                let mutables = try stations.map({ try MutableStation(from: $0, delegate: self, connection: self.connection) })
                return .Success(Set(mutables))
            } catch let error as ProperError {
                return .Failure(error)
            } catch {
                return .Failure(.unexpected(error: error))
            }
        })
    }

    func assignLetterings<Error: ErrorType>(producer: SignalProducer<[MutableStation], Error>) ->
        SignalProducer<[(String, MutableStation)], Error>
    {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
        let alphabetLength = 26
        return producer.map({ stations in
            return stations.enumerate().map({ idx, station in
                let letter = String(alphabet[alphabet.startIndex.advancedBy(idx % alphabetLength)])
                return (letter, station)
            })
        })
    }

    /**
     Construct a search rectangle given a Point and a size (defaults to a class constant).
    */
    static func searchArea(for point: Point, within radius: CLLocationDistance = searchRadius) -> MKCircle {
        return MKCircle(centerCoordinate: CLLocationCoordinate2D(point: point), radius: radius)
    }

    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return stations.value.count
    }

    // The first row in each section is the "sentinel" row, which represents the station itself rather than a particular
    // arrival at that station.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + stations.value[section].vehicles.value.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return stationCell(tableView, forRowAtIndexPath: indexPath)
        } else {
            return arrivalCell(tableView, forRowAtIndexPath: indexPath)
        }
    }

    private func stationCell(tableView: UITableView, forRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("stationCell") as! POIStationTableViewCell
        let (id, station) = letteredStations.value[indexPath.section]
        cell.apply(station, badgeIdentifier: id)
        return cell
    }

    private func arrivalCell(tableView: UITableView, forRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell") as! ArrivalTableViewCell
        cell.contentView.layoutMargins.left = 40

        // TODO: Ensure vehicles are sorted by arrival time.
        let station = stations.value[indexPath.section]
        let vehicle = station.sortedVehicles.value[indexPath.row - 1]
        cell.apply(vehicle)
        return cell
    }
}

extension MKCircle {
    func contains(coordinate other: CLLocationCoordinate2D) -> Bool {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let point = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return origin.distanceFromLocation(point) <= radius
    }
}
