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

class NearbyStationsViewModel: NSObject, UITableViewDataSource, UITableViewDelegate {

    static let searchSize = MKMapSize(width: 0.01, height: 0.01)
    static let arrivalRowHeight = CGFloat(44)
    static let stationRowHeight = CGFloat(90)

    /**
     The geographic point to base nearby stations on. Changes to this property flow through the list of nearby stations
     emitted by `stations`.

     Performance note: When `point` changes, the entire list will be reloaded, which causes an expensive RPC to
     `agency.stations`. Because of this, be judicious about modifying `point`.
     */
    let point: AnyProperty<Point>

    internal let connection: ConnectionType
    internal let disposable = CompositeDisposable()

    /**
     Produces a list of stations based on distance to `point`. The stations are implicitly subscribed to.
     
     Note: When `point` changes, the entire list will be reloaded. To gracefully animate changes to the list, you'll
     need to perform array diffs on the values emitted.
     */
    lazy var stations: AnyProperty<[MutableStation]> = { [unowned self] in
        let producer = self.producer.flatMapError({ error in
            // Errors will be sent along `subscription`. Here, they cause the property to stop updating.
            return SignalProducer<[MutableStation], NoError>(value: [])
        }).logEvents(identifier: "NearbyStationsViewModel.stations", logger: logSignalEvent)
        return AnyProperty(initialValue: [], producer: producer)
    }()

    /**
     An event producer for each station within a radius of `point` (coming from `producer`), *and* each vehicle for each
     station. Starting this producer, then, subscribes to all entities needed to populate the view model.
     */
    lazy var subscription: SignalProducer<TopicEvent, ProperError> = { [unowned self] in
        return self.producer.flatMap(.Latest, transform: { stations -> SignalProducer<TopicEvent, ProperError> in
            return SignalProducer<SignalProducer<TopicEvent, ProperError>, ProperError>(values:
                stations.map({ $0.producer })).flatten(.Merge)
        })
    }()

    lazy private var producer: SignalProducer<[MutableStation], ProperError> = { [unowned self] in
        // TODO: Consider adding a threshold to `point`s value, so that only significant changes in point reload the
        // stations.
        return self.point.producer.flatMap(.Latest, transform: { point -> SignalProducer<[MutableStation], ProperError> in
            // Compose: a search region for `point`, with a producer of static stations in that region, with a set of
            // MutableStations corresponding
            let stations = NearbyStationsViewModel.searchRect(for: point) |> self.produceStations |> self.produceMutables
            // Sort the set by distance to `point`.
            return stations.map({ $0.sortDistanceTo(point) })
        })
    }()

    init<P: PropertyType where P.Value == Point>(point: P, connection: ConnectionType = Connection.cachedInstance) {
        self.point = AnyProperty(initialValue: point.value, signal: point.signal)
        self.connection = connection
    }

    /**
     Returns a signal producer that emits stations inside the given MKMapRect.

     Implementation note: The signal producer returned calls `agency.stations`, which returns *all* stations for the
     agency and is thus very slow.
     */
    func produceStations(within rect: MKMapRect) -> SignalProducer<Set<Station>, ProperError> {
        return connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
            // Received events should be Agency.stations events, which contain a list of all stations on the agency.
            if case .Agency(.stations(let stations)) = event {
                return .Success(stations)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).decodeAnyAs(Station.self).map({ stations in
            // Filter down to a set of stations which have a defined position that is inside `rect`.
            Set(stations.filter({ $0.position.map({ MKMapRectContainsPoint(rect, MKMapPoint(point: $0)) }) == true}))
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

    /**
     Construct a search rectangle given a Point and a size (defaults to a class constant).
    */
    static func searchRect(for point: Point, within size: MKMapSize = searchSize) -> MKMapRect {
        return MKMapRect(origin: MKMapPoint(point: point), size: size)
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

    private func stationCell(tableView: UITableView, forRowAtIndexPath indexPath: NSIndexPath) ->
        StationUpcomingTableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("stationCell") as! StationUpcomingTableViewCell
        let station = stations.value[indexPath.section]
        cell.apply(station)
        return cell
    }

    private func arrivalCell(tableView: UITableView, forRowAtIndexPath indexPath: NSIndexPath) -> ArrivalTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell") as! ArrivalTableViewCell
        cell.contentView.layoutMargins.left = 40

        // TODO: Ensure vehicles are sorted by arrival time.
        let station = stations.value[indexPath.section]
        let vehicle = station.sortedVehicles.value[indexPath.row - 1]
        cell.apply(vehicle)
        if let route = vehicle.route.value {
            // TODO: Vehicles here should have a route (since we got them by traversing along a route). If not available,
            // consider displaying a loading indicator.
            cell.apply(route)
        }
        return cell
    }
}
