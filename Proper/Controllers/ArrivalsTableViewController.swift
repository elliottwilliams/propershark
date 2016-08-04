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

class ArrivalsTableViewController: UITableViewController {

    var station: MutableStation
    internal let delegate: ArrivalsTableViewDelegate
//    internal let tableView: UITableView!

    let routes: MutableProperty<Set<MutableRoute>>
    let associatedVehicles: MutableProperty<[MutableVehicle]>

    private var diffCalculator: TableViewDiffCalculator<MutableRoute>!


    // MARK: Methods

    init(observing station: MutableStation, delegate: ArrivalsTableViewDelegate, style: UITableViewStyle) {
        self.station = station
        self.delegate = delegate
        self.routes = .init([])
        self.associatedVehicles = .init([])
        super.init(style: style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // Subscribe to station updates.
        station.producer.start()

        // Create MutablesRoutes out of the routes of the station given, and update our routes property.
        let routes = station.routes.value ?? Set()
        self.routes.swap(routes)

        // Initialize the diff calculator for the table, which starts using any routes already on `station`.
        self.diffCalculator = TableViewDiffCalculator(tableView: self.tableView, initialRows: Array(routes))

        // Use our table cell UI. If the nib specified doesn't exist, `tableView(_:cellForRowAtIndexPath:)` will crash.
        self.tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")

        // Follow changes to routes and vehicles of this station.
        self.routes <~ self.routesSignal()
        self.associatedVehicles <~ self.vehiclesSignal()

        // When routes change, update the table.
        self.routes.map { self.diffCalculator.rows = Array($0) }
    }


    /// Produce a signal emitting a set of `MutableRoute`s whenever the routes on this station change.
    func routesSignal() -> Signal<Set<MutableRoute>, NoError> {
        return self.station.routes.signal.ignoreNil()
        // Start the producer for each route received, to subscribe and obtain vehicle data.
        .on(next: { routes in routes.forEach { $0.producer.start() } })
        .logEvents(identifier: "ArrivalTableViewController.routesSignal", logger: logSignalEvent)
    }

    /// Access the `routes` attribute of this station and produce a signal which emits a list vehicles pairs
    /// every time the vehicle association changes for a particular route.
    func vehiclesSignal() -> Signal<[MutableVehicle], NoError> {

        // Given a signal emitting the list of MutableRoutes for this station...
        return self.routesSignal()
        // ...flatMap down to the routes themselves...
        .flatMap(.Concat) { routes in SignalProducer<MutableRoute, NoError>(values: routes) }
        // ...and access the vehicles property of each.
        .map { route in route.vehicles.signal }
        // We now have a signal of signals of vehicles, which emits whever the list of routes changes.
        // Flatten this into a signal of vehicles that emits whenever a route:vehicles association changes.
        .flatten(.Merge)
        // If vehicle set is nil, default to an empty set.
        .map { $0 ?? Set() }
        // Sort by arrival time (TODO: actually do this)
        .map { Array($0) }
        .logEvents(identifier: "ArrivalTableViewController.vehiclesSignal", logger: logSignalEvent)
    }


    // MARK: Delegate Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? { return "Arrivals" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return associatedVehicles.value.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // ArrivalTableViewCell comes from the xib, and is registered upon the creation of this table
        let cell = tableView.dequeueReusableCellWithIdentifier("ArrivalTableViewCell", forIndexPath: indexPath) as! ArrivalTableViewCell
        let vehicle = associatedVehicles.value[indexPath.row]

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