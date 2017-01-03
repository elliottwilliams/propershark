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
import MapKit
import GameKit

class NearbyStationsViewModel: NSObject, UITableViewDataSource, MutableModelDelegate {

    // TODO - Maybe raise the search radius but cap the number of results returned?
    static let searchRadius = CLLocationDistance(250) // in meters
    static let arrivalRowHeight = CGFloat(44)

    /**
     The geographic point to base nearby stations on. Changes to this property flow through the list of nearby stations
     emitted by `stations`.

     Performance note: When `point` changes, the entire list will be reloaded, which causes an expensive RPC to
     `agency.stations`. Because of this, be judicious about modifying `point`.
     */
    let point: AnyProperty<Point>

    internal let connection: ConnectionType
    internal let disposable = CompositeDisposable()
    private let distanceFormatter = MKDistanceFormatter()

    let stations: MutableProperty<[MutableStation]> = .init([])
    var distances = [MutableStation: String]()
    var badges = [MutableStation: StationBadge]()

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
        super.init()

        disposable += produceBadges(stations.producer).startWithNext({ station, badge in
            self.badges[station] = badge
        })

        disposable += produceDistances(stations.producer).startWithNext({ station, distance in
            self.distances[station] = distance
        })
    }

    deinit {
        disposable.dispose()
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

    func produceBadges<Error: ErrorType>(producer: SignalProducer<[MutableStation], Error>) ->
        SignalProducer<(MutableStation, StationBadge), Error>
    {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
        let alphabetLength = 26
        return producer.flatMap(.Latest, transform: { stations -> SignalProducer<(MutableStation, StationBadge), Error> in
            let badges = stations.enumerate().map({ idx, station -> (MutableStation, StationBadge) in
                let letter = String(alphabet[alphabet.startIndex.advancedBy(idx % alphabetLength)])
                let badge = StationBadge(name: letter, seedForColor: station.identifier)
                return (station, badge)
            })
            return SignalProducer(values: badges)
        })
    }

    func produceDistances<Error: ErrorType>(stations: SignalProducer<[MutableStation], Error>,
                          point: SignalProducer<Point, NoError>) -> SignalProducer<(MutableStation, String), Error> {
        return stations.flatMap(.Latest, transform: { stations -> SignalProducer<MutableStation, Error> in
            return SignalProducer(values: stations)
        }).flatMap(.Merge, transform: { station -> SignalProducer<(MutableStation, String), NoError> in
            let stationProducer = SignalProducer<MutableStation, NoError>(value: station)
            let position = station.position.producer.ignoreNil()
            let distance = position.combineLatestWith(point).map({ to, from in
                self.distanceFormatter.stringFromDistance(to.distanceFrom(from))
            })

            return stationProducer.combineLatestWith(distance)
        })
    }

//    func producePOIStations<Error: ErrorType>(producer: SignalProducer<[MutableStation], Error>) {
////        produce
//    }

    struct POIStation {
        let station: MutableStation
        let badge: AnyProperty<StationBadge>
        let distance: AnyProperty<String>
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
        return stations.value[section].vehicles.value.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell") as! ArrivalTableViewCell
        cell.contentView.layoutMargins.left = 40

        // TODO: Ensure vehicles are sorted by arrival time.
        let station = stations.value[indexPath.section]
        let vehicle = station.sortedVehicles.value[indexPath.row]
        cell.apply(vehicle)
        return cell
    }
}

internal struct StationBadge {
    let name: String
    let color: UIColor

    init(name: String, color: UIColor) {
        self.name = name
        self.color = color
    }

    init<H: Hashable>(name: String, seedForColor seed: H) {
        self.name = name
        self.color = StationBadge.randomColor(seed)
    }

    /**
     Generate a pseudorandom color given a hashable seed. Using this generator, badges can have a color generated from
     the station's identifier.
     */
    static func randomColor<H: Hashable>(seed: H) -> UIColor {
        let src = GKMersenneTwisterRandomSource(seed: UInt64(abs(seed.hashValue)))
        let gen = GKRandomDistribution(randomSource: src, lowestValue: 0, highestValue: 255)
        let h = CGFloat(gen.nextInt()) / 256.0
        // Saturation and luminance stay between 0.5 and 1.0 to avoid white and excessively dark colors.
        let s = CGFloat(gen.nextInt()) / 512.0 + 0.5
        let l = CGFloat(gen.nextInt()) / 512.0 + 0.5
        return UIColor(hue: h, saturation: s, brightness: l, alpha: CGFloat(1))
    }
}

extension MKCircle {
    func contains(coordinate other: CLLocationCoordinate2D) -> Bool {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let point = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return origin.distanceFromLocation(point) <= radius
    }
}
