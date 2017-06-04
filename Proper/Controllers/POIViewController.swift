//
//  POIViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import MapKit
import CoreLocation

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate {
    // MARK: Point properties
    typealias NamedPoint = POIViewModel.NamedPoint

    @IBOutlet weak var stackView: UIStackView!
    
    /// Map annotation for the point of interest represented by this view. Only used for static locations.
    let annotation = MKPointAnnotation()

    var tableController: POITableViewController!
    var mapController: POIMapViewController!

    /// The point tracked by the POI view. May be either the user's location or a static point. While the view is
    /// visible, this point is from `staticLocation` or `deviceLocation`, depending on whether a static location was
    /// passed.
    lazy var point = MutableProperty<Point>(Point(coordinate: Config.agency.region.center))

    /// The area represented by the map, which stations are searched for within.
    lazy var zoom = MutableProperty<CLLocationDistance>(250) // Default zoom of 250m

    lazy var isUserLocation = MutableProperty(true)

    // Stations found within the map area. This producer is passed to the POITableViewController and is a basis for its
    // view model.
    lazy var stations = MutableProperty<[MutableStation]>([])
    lazy var routes: Property<Set<MutableRoute>> = {
        return self.stations.flatMap(.latest, transform: { stations -> Property<Set<MutableRoute>> in
            let producers = stations.map({ $0.routes.producer })
            let routes = SignalProducer(producers).flatten(.merge).flatten().reduce(Set(), { set, route in
                set.union([route] as Set)
            })
            return Property(initial: Set(), then: routes)
        })
    }()

    /// A producer for the device's location, which adds metadata used by the view into the signal. It is started when
    /// the view appears, but is interrupted if a static location is passed by `staticLocation`.
    let deviceLocation = Location.producer |> POIViewModel.distinctLocations

    /// A producer for a "static location" of the view. This static location overrides the device location and makes the
    /// view represent the latest point passed.
    var staticLocation = SignalProducer<NamedPoint, ProperError>.never

    /// A producer that merges `deviceLocation` and `staticLocation`. The device location will be used until 
    /// `staticLocation` emits a `NamedPoint`, at which point the producer is replaced by `staticLocation`.
    var location: SignalProducer<NamedPoint, ProperError> {
        return deviceLocation.take(untilReplacement: staticLocation)
    }

    private let searchScheduler = QueueScheduler(qos: .userInitiated, name: "searchScheduler")

    // MARK: Conformances
    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    func apply(operations ops: [POIViewModel.Op]) {
        ops.forEach { op in
            switch op {
            case let .addStation(station, index: idx):
                self.mapController?.addAnnotation(for: station, at: idx)
            case let .deleteStation(station, at: _):
                self.mapController?.deleteAnnotations(for: station)
            case let .reorderStation(_, from: fi, to: ti):
                self.mapController?.reorderAnnotations(withIndex: fi, to: ti)
            default: return
            }
        }
    }
    
    // MARK: Lifecycle

    private func loadMapController() {
        let onSelect: Action<MutableStation, (), NoError> = Action { station in
            let section = self.tableController.dataSource.index(of: station)
            let row = (self.tableController.dataSource.arrivals[section].isEmpty) ? NSNotFound : 0
            self.tableController.tableView.scrollToRow(at: IndexPath(row: row, section: section),
                                                       at: .top,
                                                       animated: true)
            return SignalProducer.empty
        }

        let mapController = POIMapViewController(center: point,
                                                 zoom: zoom,
                                                 routes: Property(routes),
                                                 onSelect: onSelect,
                                                 isUserLocation: Property(isUserLocation))
        addChildViewController(mapController)
        stackView.insertArrangedSubview(mapController.view, at: 0)
        mapController.view.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.4).isActive = true
        mapController.didMove(toParentViewController: self)
        self.mapController = mapController
    }

    private func loadTableController() {
        let tableController = POITableViewController(style: .plain,
                                                     stations: Property(stations),
                                                     mapPoint: Property(point))
        addChildViewController(tableController)
        stackView.addArrangedSubview(tableController.view)
        tableController.view.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.6).isActive = true
        tableController.didMove(toParentViewController: self)
        self.tableController = tableController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapController()
        loadTableController()

        // Clear the title until the signals created in `viewWillAppear` set one.
        navigationItem.title = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make the navigation bar fully transparent.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        }

        let searchProducer = point.producer.combineLatest(with: zoom.producer)
            .throttle(0.5, on: searchScheduler)
            .logEvents(identifier: "NearbyStationsViewModel.chain input",
                       logger: logSignalEvent)

        // Search for nearby stations.
        disposable += NearbyStationsViewModel.chain(connection: connection, producer: searchProducer)
            .startWithResult() { result in
                switch result {
                case let .success(stations):    self.stations.swap(stations)
                case let .failure(error):       self.displayError(error)
                }
            }

        // Using location, update the map.
        disposable += location.startWithResult { result in
            switch result {
            case let .success(point, name, isUserLocation):
                self.point.swap(point)
                self.navigationItem.title = name
                self.isUserLocation.swap(isUserLocation)
            case let .failure(error):
                self.displayError(error)
            }
        }

        // Show nearby stations on the map.
        disposable += POIViewModel.chain(connection: connection, producer: stations.producer).startWithResult({ result in
            switch result {
            case let .failure(error):
                self.displayError(error)
            case let .success(ops):
                self.apply(operations: ops)
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Reset the navigation bar.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(nil, for: UIBarMetrics.default)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposable.dispose()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "showStation":
            let station = sender as! MutableStation
            let dest = segue.destination as! StationViewController
            dest.station = station
        default:
            return
        }
    }
}
