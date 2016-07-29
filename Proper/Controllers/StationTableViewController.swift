//
//  StationTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 7/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft
import Result

class StationArrivalsTableViewController: UITableViewController, MutableModelDelegate {

    var station: MutableStation
    let delegate: StationTableViewDelegate

    let routes: MutableProperty<[MutableRoute]>
    let associatedVehicles: MutableProperty<[VehicleOnRoute]>

    private var diffCalculator: TableViewDiffCalculator<MutableRoute>!


    // MARK: Methods

    init(observing station: MutableStation, delegate: StationTableViewDelegate, view: UITableView) {
        self.station = station
        self.delegate = delegate
        self.routes = .init([])
        self.associatedVehicles = .init([])
        super.init(style: view.style)

        // Create MutablesRoutes out of the routes of the station given, and update our routes property.
        let routes = station.routes.value.map { MutableRoute(from: $0, delegate: self) }
        self.routes.swap(routes)

        // Initialize the diff calculator for the table, which starts using any routes already on `station`.
        self.diffCalculator = TableViewDiffCalculator(tableView: view, initialRows: routes)

        // Use our table cell UI. If the nib specified doesn't exist, `tableView(_:cellForRowAtIndexPath:)` will crash.
        view.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")

        // Follow changes to routes and vehicles of this station.
        self.routes <~ self.routesSignal()
        self.associatedVehicles <~ self.vehiclesSignal()

        // Connect the table view to this controller now that everything is initialized.
        self.view = view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    /// Produce a signal emitting a list of `MutableRoute`s whenever the routes on this station change.
    ///
    /// Complexity within signal: O(routes)
    func routesSignal() -> Signal<[MutableRoute], NoError> {
        return self.station.routes.signal
            .map { routes in
                routes.map { route in MutableRoute(from: route, delegate: self) }
        }
    }

    /// Access the `routes` attribute of this station and produce a signal which emits a list of (route,vehicle) pairs
    /// every time the vehicle association changes for a particular route.
    ///
    /// Complexity within signal: O(vehicles)
    func vehiclesSignal() -> Signal<[VehicleOnRoute], NoError> {

        // Given a signal emitting the list of MutableRoutes for this station...
        return self.routesSignal()
            // ...flatMap down to the routes themselves...
            .flatMap(.Concat) { routes in SignalProducer<MutableRoute, NoError>(values: routes) }
            // ...and access the vehicles property of each. Map to a (route,vehicles) tuple so that route association
            // information isn't lost downstream.
            .map { route in
                route.vehicles.signal.map { (route, $0) }
            }
            // We now have a signal of signals of (route,vehicles) tuples, which emits whever the list of routes changes.
            // Flatten this into a signal of (route,vehicles) tuples that emits whenever a route:vehicles association
            // changes.
            .flatten(.Merge)
            // Convert the (route,vehicles) tuple into a list of vehicle-route associations. By using an association struct,
            // values from the signal are Equatable and can be used for diffing.
            .map { (route, vehicles) in
                vehicles.map { VehicleOnRoute(vehicle: $0, route: route) }
        }
    }


    // MARK: Delegate Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? { return "Arrivals" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return associatedVehicles.value.count }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // ArrivalTableViewCell comes from the xib, and is registered upon the creation of this table
        let cell = tableView.dequeueReusableCellWithIdentifier("ArrivalTableViewCell", forIndexPath: indexPath) as! ArrivalTableViewCell
        let association = associatedVehicles.value[indexPath.row]
        let (route, vehicle) = (association.route, association.vehicle)

        cell.badge.routeNumber = route.code
        route.name.map { cell.routeTitle.text = $0 }
        route.color.map { color in
            color.flatMap { cell.badge.color = $0 }
        }

        cell.badge.capacity = vehicle.saturation ?? 1
        cell.routeTimer.text = "Schedule delta = \(vehicle.scheduleDelta)"

        return cell
    }

    func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
        // Pass upwards to parent delegate
        self.delegate.mutableModel(model, receivedError: error)
    }

    
}

protocol StationTableViewDelegate: MutableModelDelegate {
    func selectedStation(station: Station, indexPath: NSIndexPath)
}



struct VehicleOnRoute: Equatable {
    let vehicle: Vehicle
    let route: MutableRoute
}

func ==(a: VehicleOnRoute, b: VehicleOnRoute) -> Bool {
    return a.route == b.route && a.vehicle == b.vehicle
}