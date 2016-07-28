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

    private let diffCalculator: TableViewDiffCalculator<MutableRoute>
    var routes: [MutableRoute] { return self.diffCalculator.rows }

    init(observing station: MutableStation, delegate: StationTableViewDelegate, view: UITableView) {
        self.station = station
        self.delegate = delegate

//        self.diffCalculator = TableViewDiffCalculator(tableView: view, initialRows: station.routes.value)

        super.init(style: view.style)
        self.view = view

        // Use our table cell UI. If the nib specified doesn't exist, this will crash.
        view.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")

        // Bind the diff calculator to new routes on the signal, so that it will update rows of
        // `view` as the routes on the station change.
//        station.routes.signal.ignoreNil().observeNext { routes in
//            self.diffCalculator.rows = routes.map { MutableRoute(from: $0, delegate: self) }
//        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Unpack the vehicles on a list of routes down to a list of (route,vehicle) pairs.
    static func vehiclesOn(station: MutableStation) -> Signal<(MutableRoute, MutableVehicle), NoError> {
        // Take the latest set of routes known to this station...
        let freshRoutes = station.routes.signal.flatten(.Latest)
        // ...select the vehicles for those routes, and merge down to a list of vehicles on routes of the station.
        // first flatten goes from a (list of (signals producing lists of vehicles)) to a (signal producing lists of 
        // vehicles), second flatten goes to a (signal producing vehicles)
        let vehicles = freshRoutes.map { route in route.vehicles.signal }.flatten(.Merge).flatten(.Merge)
        let routes = freshRoutes.map { route in [MutableRoute](count: route.vehicles.value.count, repeatedValue: route) }.flatten(.Merge)
        return routes.zipWith(vehicles)
    }

    // MARK: Delegate Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? { return "Arrivals" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return routes.count }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // ArrivalTableViewCell comes from the xib, and is registered upon the creation of this table
        let cell = tableView.dequeueReusableCellWithIdentifier("ArrivalTableViewCell", forIndexPath: indexPath) as! ArrivalTableViewCell
        let route = routes[indexPath.row]

        cell.badge.routeNumber = route.code
        route.name.map { cell.routeTitle.text = $0 }
    }

    func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
        // Pass upwards to parent delegate
        self.delegate.mutableModel(model, receivedError: error)
    }
}

protocol StationTableViewDelegate: MutableModelDelegate {
    func selectedStation(station: Station, indexPath: NSIndexPath)
}