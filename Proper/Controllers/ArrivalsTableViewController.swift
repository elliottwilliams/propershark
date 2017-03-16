//
//  ArrivalsTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 7/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft
import Result

class ArrivalsTableViewController: UITableViewController, ProperViewController {

    var station: MutableStation!
    var delegate: ArrivalsTableViewDelegate!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.cachedInstance
    internal var diffCalculator: TableViewDiffCalculator<MutableVehicle>!
    internal var disposable = CompositeDisposable()
    internal var routeDisposables = [MutableRoute: Disposable]()

    internal weak var routesCollectionView: UICollectionView?
    internal var routesCollectionModel: RoutesCollectionViewModel!

    // MARK: Signalled properties
    lazy var vehicles: AnyProperty<Set<MutableVehicle>> = {
        // Given a signal emitting the list of MutableRoutes for this station...
        let producer = self.station.routes.producer
        // ...flatMap down to a joint set of vehicles.
        .flatMap(.Latest) { (routes: Set<MutableRoute>) -> SignalProducer<Set<MutableVehicle>, NoError> in

            // Each member of `routes` has a producer for vehicles on that route. Combine the sets produced by each
            // producer into a joint set.

            // Obtain the first set's producer and combine all other sets' producers with this one. Return an empty set
            // if there are no routes in the set.
            guard let firstProducer = routes.first?.vehicles.producer else {
                return SignalProducer(value: Set())
            }

            return routes.dropFirst().reduce(firstProducer) { producer, route in
                let vehicles = route.vehicles.producer
                // `combineLatest` causes the producer to wait until the two signals being combines have emitted. In
                // this case, it means that no vehicles will be forwarded until all routes have produced a list of
                // vehicles. After that, changes to vehicles of any route will forward the entire set again.
                return producer.combineLatestWith(vehicles).map { $0.union($1) }
            }
        }

        return AnyProperty(initialValue: Set(), producer: producer)
    }()

    // MARK: Methods
    convenience init(observing station: MutableStation, delegate: ArrivalsTableViewDelegate, style: UITableViewStyle,
                               connection: ConnectionType)
    {
        self.init(style: style)
        self.station = station
        self.delegate = delegate
        self.connection = connection
    }

    override func viewDidLoad() {
        // Initialize the diff calculator for the table, which starts using any routes already on `station`.
        diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialRows: vehicles.value.sort())
        diffCalculator.sectionIndex = 1

        // Create a controller to manage the routes collection view within the table.
        routesCollectionModel = RoutesCollectionViewModel(routes: AnyProperty(station.routes))

        // Register the arrival nib for use in the table.
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "arrivalCell")
    }

    override func viewDidAppear(animated: Bool) {
        // Follow changes to the station.
        disposable += station.producer.startWithFailed(self.delegate.arrivalsTable(receivedError:))

        // Follow changes to routes on the station. As routes are associated and disassociated, maintain signals on all
        // current routes, so that vehicle information can be obtained. Dispose these signals as routes go away.
        disposable += station.routes.producer.combinePrevious(Set())
            .startWithNext { old, new in
                new.subtract(old).forEach { route in
                    self.routeDisposables[route] = route.producer.startWithFailed(self.delegate.arrivalsTable(receivedError:))
                    self.disposable += self.routeDisposables[route]
                }
                old.subtract(new).forEach { route in
                    self.routeDisposables[route]?.dispose()
                }
        }

        // When the list of vehicles for this station changes, update the table.
        disposable += vehicles.producer.startWithNext { vehicles in
            self.tableView.beginUpdates()
            self.diffCalculator.rows = vehicles.sort()
            self.tableView.endUpdates()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    // Bind vehicle attributes to a given cell
    func arrivalCell(for indexPath: NSIndexPath) -> ArrivalTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell", forIndexPath: indexPath) as! ArrivalTableViewCell
        let vehicle = diffCalculator.rows[indexPath.row]

//        cell.apply(vehicle)
        return cell
    }

    // Get a cell for displaying the routes collection, and connect it to the routes collection controller instantiated
    // at start. Since there is only one routes collection cell (its `numbersOfRows` call always returns 1), the
    // assignment onto `routesCollection` won't overwrite some other cell.
    func routesCollectionCell(for indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("routesCollectionCell", forIndexPath: indexPath) as! ArrivalTableRouteCollectionCell
        cell.bind(routesCollectionModel)
        
        // Store a weak reference to the cell's collection view so that we can examine its state without needing a
        // a reference to this particular table view cell.
        routesCollectionView = cell.collectionView
        return cell
    }

    // MARK: Table View Delegate Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 2 }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Routes Served", "Arrivals"][section]
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [1, diffCalculator.rows.count][section]
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // The routes collection cell has a custom height, while other cells go off of the table view's default. 
        return [70, tableView.rowHeight][indexPath.section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return routesCollectionCell(for: indexPath)
        case 1:
            return arrivalCell(for: indexPath)
        default:
            fatalError("Bad ArrivalsTable section number (\(indexPath.section))")
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "showRoute":
            let dest = segue.destinationViewController as! RouteViewController
            let index = routesCollectionView!.indexPathsForSelectedItems()!.first!
            let route = routesCollectionModel.routes.value[index.row]
            dest.route = route
        default:
            return
        }
    }
}

protocol ArrivalsTableViewDelegate: MutableModelDelegate {
    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath)
    func arrivalsTable(receivedError error: ProperError)
}



struct VehicleOnRoute: Equatable {
    let vehicle: Vehicle
    let route: MutableRoute
}

func ==(a: VehicleOnRoute, b: VehicleOnRoute) -> Bool {
    return a.route == b.route && a.vehicle == b.vehicle
}
