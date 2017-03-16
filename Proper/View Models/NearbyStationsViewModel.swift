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
    static let defaultSearchRadius = CLLocationDistance(250) // in meters
    static let arrivalRowHeight = CGFloat(44)

    /**
     The geographic point to base nearby stations on. Changes to this property flow through the list of nearby stations
     emitted by `stations`.

     Performance note: When `point` changes, the entire list will be reloaded, which causes an expensive RPC to
     `agency.stations`. Because of this, be judicious about modifying `point`.
     */
    let point: AnyProperty<Point?>
    let searchRadius: AnyProperty<CLLocationDistance>

    /**
     The station-arrivals data represented by the view model. View controllers update this property as they respond to
     changes from `producer`.
     */
    let model: MutableProperty<[(MutableStation, [Arrival])]> = .init([])

    /// A convenience mapping of `current` that represents nearby stations. Indexed by position in the table.
    let stations: AnyProperty<[MutableStation]>
    /// A convenience mapping of `current` that represents nearby arrivals. Indexed by table section and arrival
    /// sequence.
    let arrivals: AnyProperty<[[Arrival]]>

    var distances = [MutableStation: AnyProperty<String?>]()
    var badges = [MutableStation: Badge]()

    internal let connection: ConnectionType
    internal let disposable = CompositeDisposable()
    private let distanceFormatter = MKDistanceFormatter()

    lazy var producer: SignalProducer<[(MutableStation, [Arrival])], ProperError> = { [unowned self] in
        let rect = combineLatest(self.point.producer.ignoreNil(), self.searchRadius.producer)
            .map({ point, radius -> MKMapRect in
                let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(point: point), radius: radius)
                return circle.boundingMapRect
            }).promoteErrors(ProperError)
        return rect |> self.nearbyStations |> self.addArrivals
    }()

    init<P: PropertyType, Q: PropertyType where P.Value == Point?, Q.Value == CLLocationDistance>
        (point: P, searchRadius: Q, connection: ConnectionType = Connection.cachedInstance)
    {
        self.point = AnyProperty(point)
        self.searchRadius = AnyProperty(searchRadius)

        self.stations = self.model.map({ tuples in tuples.lazy.map({ st, ar in st }) })
        self.arrivals = self.model.map({ tuples in tuples.lazy.map({ st, ar in ar }) })
        self.connection = connection
        super.init()

        disposable += badges(for: stations.producer)
            .startWithNext({ station, badge in
                self.badges[station] = badge
            })
        disposable += distances(for: stations.producer, from: point.producer.ignoreNil())
            .startWithNext({ station, distance in
                self.distances[station] = distance
            })
    }

    deinit {
        disposable.dispose()
    }

    /**
     Returns a signal producer that emits stations inside the a given circle defined by the positional `point` and 
     `radius` parameters inside the signal.

     Implementation note: The signal producer returned calls `agency.stations`, which returns *all* stations for the
     agency and is thus very slow.
     */
    func nearbyStations(rect: SignalProducer<MKMapRect, ProperError>) ->
        SignalProducer<[MutableStation], ProperError>
    {
        let stations = connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
            // Received events should be Agency.stations events, which contain a list of all stations on the agency.
            if case .Agency(.stations(let stations)) = event {
                return .Success(stations)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).decodeAnyAs(Station.self)

        return combineLatest(stations, rect).map({ stations, rect -> ([Station], MKMapRect) in
            // Filter down to a set of stations which have a defined position that is inside `circle`.
            let nearby = stations.filter({ $0.position.map({ MKMapRectContainsPoint(rect, MKMapPoint(point: $0)) }) == true })
            return (nearby, rect)
        }).attemptMap({ stations, rect -> Result<([MutableStation], MKMapRect), ProperError> in
            // Attempt to create MutableStations out of all stations.
            do {
                let mutables = try stations.map({ try MutableStation(from: $0, delegate: self, connection: self.connection) })
                return .Success(mutables, rect)
            } catch let error as ProperError {
                return .Failure(error)
            } catch {
                return .Failure(.unexpected(error: error))
            }
        }).map({ stations, rect -> [MutableStation] in
            let center = MKCoordinateRegionForMapRect(rect).center
            return stations.sortDistanceTo(Point(coordinate: center))
        })
    }

    func badges<Error: ErrorType>(for producer: SignalProducer<[MutableStation], Error>) ->
        SignalProducer<(MutableStation, Badge), Error>
    {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
        let alphabetLength = 26
        return producer.flatMap(.Latest, transform: { stations -> SignalProducer<(MutableStation, Badge), Error> in
            let badges = stations.enumerate().map({ idx, station -> (MutableStation, Badge) in
                let letter = String(alphabet[alphabet.startIndex.advancedBy(idx % alphabetLength)])
                let badge = Badge(name: letter, seedForColor: station.identifier)
                return (station, badge)
            })
            return SignalProducer(values: badges)
        })
    }

    func distances<Error: ErrorType>(for stations: SignalProducer<[MutableStation], Error>,
                   from point: SignalProducer<Point, NoError>) ->
        SignalProducer<(MutableStation, AnyProperty<String?>), Error>
    {
        return stations.flatMap(.Latest, transform: { stations -> SignalProducer<MutableStation, Error> in
            return SignalProducer(values: stations)
        }).map({ station in
            let position = station.position.producer.ignoreNil()
            let distance = position.combineLatestWith(point).map({ to, from in
                self.distanceFormatter.stringFromDistance(to.distanceFrom(from))
            }).map({ Optional($0) })
            let property = AnyProperty(initialValue: nil, producer: distance)

            return (station, property)
        })
    }

    // [Station] -> [(Station, [Arrival])]
    func addArrivals(to producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<[(MutableStation, [Arrival])], ProperError>
    {
        return producer.flatMap(.Latest, transform: { stations -> SignalProducer<[(MutableStation, [Arrival])], ProperError> in
            let p = SignalProducer<MutableStation, ProperError>(values: stations)
            return p.flatMap(.Merge, transform: { station in
                combineLatest(
                    SignalProducer(value: station),
                    Timetable.visits(for: station,
                        occurring: .between(from: NSDate(), to: NSDate(timeIntervalSinceNow: 60*60)),
                        using: self.connection).collect()
                )
            }).collect()
        }).logEvents(identifier: "NearbyStationsViewModel.addArrivals", logger: logSignalEvent)
    }


    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return stations.value.count
    }

    // Return the number of arrivals for each route on the each station of the section given.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let (_, arrivals) = model.value[section]
        return arrivals.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell") as! ArrivalTableViewCell
        cell.contentView.layoutMargins.left = 40

        //let station = stations.value[indexPath.section]
        let arrival = arrivals.value[indexPath.section][indexPath.row]
        // TODO - Apply route and arrival information to the view
        cell.apply(arrival)
        return cell
    }

    /**
     Data representing a station's badge. The badge consists of a name and a color. `Badge` instances are used to create
     `BadgeView` instances, which render badges in the UI.
     */
    struct Badge {
        let name: String
        let color: UIColor

        init(name: String, color: UIColor) {
            self.name = name
            self.color = color
        }

        init<H: Hashable>(name: String, seedForColor seed: H) {
            self.name = name
            self.color = Badge.randomColor(seed)
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
}

extension MKCircle {
    func contains(coordinate other: CLLocationCoordinate2D) -> Bool {
        let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let point = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return origin.distanceFromLocation(point) <= radius
    }
}
