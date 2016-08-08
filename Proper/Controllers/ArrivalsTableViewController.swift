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
    internal let delegate: ArrivalsTableViewDelegate

    lazy var routes: AnyProperty<Set<MutableRoute>> = {
        return AnyProperty(initialValue: Set(), producer: self.station.routes.producer.ignoreNil())
    }()

    /// A signal which emits a list of vehicles every time the vehicle association changes for a particular route.
    lazy var vehicles: AnyProperty<[MutableVehicle]> = {
        // Given a signal emitting the list of MutableRoutes for this station...
        let producer = self.routes.producer
        // ...flatMap down to the routes themselves...
        .flatMap(.Concat) { routes in SignalProducer(values: routes) }
        // ...and access the vehicles property of each.
        .map { route in route.vehicles.signal }
        // We now have a signal of signals of vehicles, which emits whever the list of routes changes.
        // Flatten this into a signal of vehicles that emits whenever a route:vehicles association changes.
        .flatten(.Merge)
        // If vehicle set is nil, default to an empty set.
        .map { $0 ?? Set() }
        // Sort by arrival time (TODO: actually do this)
        .map { Array($0) }

        return AnyProperty(initialValue: [], producer: producer)
    }()

    func foo() {
        let prop = MutableProperty<[MutableVehicle]>([])
        prop <~ vehicles
    }

    internal var diffCalculator: TableViewDiffCalculator<MutableVehicle>!

    internal var connection: ConnectionType
    internal var config: Config

    // MARK: Methods

    init(observing station: MutableStation, delegate: ArrivalsTableViewDelegate, style: UITableViewStyle,
                   connection: ConnectionType, config: Config)
    {
        self.station = station
        self.delegate = delegate
        self.connection = connection
        self.config = config
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // Initialize the diff calculator for the table, which starts using any routes already on `station`.
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialRows: vehicles.value)

        // Use our table cell UI. If the nib specified doesn't exist, `tableView(_:cellForRowAtIndexPath:)` will crash.
        self.tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")

        // Follow changes to the station and its routes.
        station.producer.takeUntil(self.onDisappear()).startWithFailed(self.delegate.arrivalsTable(receivedError:))

        var routeDisposables = [MutableRoute: Disposable]()
        routes.producer.takeUntil(self.onDisappear())
        .combinePrevious(Set())
        .startWithNext { old, new in
            new.subtract(old).forEach { route in
                routeDisposables[route] = route.producer.startWithFailed(self.delegate.arrivalsTable(receivedError:))
            }
            old.subtract(new).forEach { route in
                routeDisposables[route]?.dispose()
            }
        }

        // When the list of vehicles for this station changes, update the table.
        self.vehicles.producer.takeUntil(self.onDisappear()).startWithNext { vehicles in
            self.diffCalculator.rows = vehicles
        }
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
        let vehicle = vehicles.value[indexPath.row]

        // Bind vehicle attributes
        vehicle.saturation.map { cell.badge.capacity = $0 ?? 1 }
        vehicle.scheduleDelta.map { cell.routeTimer.text = "Schedule ∆ = \($0)" }

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