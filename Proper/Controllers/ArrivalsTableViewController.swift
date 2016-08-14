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

    var station: MutableStation

    // MARK: Internal properties
    internal let delegate: ArrivalsTableViewDelegate
    internal var diffCalculator: TableViewDiffCalculator<MutableVehicle>!
    internal var connection: ConnectionType

    // MARK: Signalled properties
    lazy var routes: AnyProperty<Set<MutableRoute>> = {
        return AnyProperty(initialValue: Set(), producer: self.station.routes.producer.ignoreNil())
    }()

    lazy var vehicles: AnyProperty<Set<MutableVehicle>> = {
        // Given a signal emitting the list of MutableRoutes for this station...
        let producer = self.routes.producer
        // ...flatMap down to a joint set of vehicles.
        .flatMap(.Latest) { (routes: Set<MutableRoute>) -> SignalProducer<Set<MutableVehicle>, NoError> in

            // Each member of `routes` has a producer for vehicles on that route. Combine the sets produced by each
            // producer into a joint set.

            // Obtain the first set's producer and combine all other sets' producers with this one. Return an empty set
            // if there are no routes in the set.
            guard let firstProducer = routes.first?.vehicles.producer.ignoreNil() else {
                return SignalProducer(value: Set())
            }

            return routes.dropFirst().reduce(firstProducer) { producer, route in
                let vehicles = route.vehicles.producer.ignoreNil()
                // `combineLatest` causes the producer to wait until the two signals being combines have emitted. In
                // this case, it means that no vehicles will be forwarded until all routes have produced a list of
                // vehicles. After that, changes to vehicles of any route will forward the entire set again.
                return producer.combineLatestWith(vehicles).map { $0.union($1) }
            }
        }

        return AnyProperty(initialValue: Set(), producer: producer)
    }()


    // MARK: Methods
    init(observing station: MutableStation, delegate: ArrivalsTableViewDelegate, style: UITableViewStyle,
                   connection: ConnectionType)
    {
        self.station = station
        self.delegate = delegate
        self.connection = connection
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal var disposable = CompositeDisposable()
    internal var routeDisposables = [MutableRoute: Disposable]()

    override func viewDidLoad() {
        // Initialize the diff calculator for the table, which starts using any routes already on `station`.
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialRows: vehicles.value.sort())

        // Use our table cell UI. If the nib specified doesn't exist, `tableView(_:cellForRowAtIndexPath:)` will crash.
        self.tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")

        // When the list of vehicles for this station changes, update the table.
        self.vehicles.producer.takeUntil(self.onDisappear()).startWithNext { vehicles in
            self.diffCalculator.rows = vehicles.sort()
        }
    }

    override func viewDidAppear(animated: Bool) {
        // Follow changes to the station and its routes.
        disposable += station.producer.startWithFailed(self.delegate.arrivalsTable(receivedError:))

        disposable += routes.producer.combinePrevious(Set())
            .startWithNext { old, new in
                new.subtract(old).forEach { route in
                    self.routeDisposables[route] = route.producer.startWithFailed(self.delegate.arrivalsTable(receivedError:))
                    self.disposable += self.routeDisposables[route]
                }
                old.subtract(new).forEach { route in
                    self.routeDisposables[route]?.dispose()
                }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }


    // MARK: Delegate Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return "Arrivals" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return diffCalculator.rows.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // ArrivalTableViewCell comes from the xib, and is registered upon the creation of this table
        let cell = tableView.dequeueReusableCellWithIdentifier("ArrivalTableViewCell", forIndexPath: indexPath) as! ArrivalTableViewCell
        let vehicle = diffCalculator.rows[indexPath.row]

        // Bind vehicle attributes
        cell.vehicleName.text = "(Bus #\(vehicle.name))"
        vehicle.saturation.map { cell.badge.capacity = $0 ?? 1 }
        vehicle.scheduleDelta.map { cell.routeTimer.text = "∆\($0) min" }

        guard let route = vehicle.route.value else {
            // Vehicles here should have a route (since we got them by traversing along a route). If not available,
            // consider displaying a loading indicator.
            return cell
        }

        // Bind route attributes
        cell.badge.routeNumber = route.shortName
        route.name.map { cell.routeTitle.text = $0 }
        route.color.map { color in
            color.flatMap { cell.badge.color = $0 }
        }

        return cell
    }
}

protocol ArrivalsTableViewDelegate: MutableModelDelegate {
    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath)
    func arrivalsTable(receivedError error: PSError)
}



struct VehicleOnRoute: Equatable {
    let vehicle: Vehicle
    let route: MutableRoute
}

func ==(a: VehicleOnRoute, b: VehicleOnRoute) -> Bool {
    return a.route == b.route && a.vehicle == b.vehicle
}