//
//  StartListViewController.swift
//  Proper
//
//  Created by Elliott Williams on 12/24/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import Argo

class StartListViewController: UITableViewController, ProperViewController {
    
    // MARK: Properties
    var routes: [Route] = []
    var stations: [Station] = []
    var vehicles: [Vehicle] = []

    internal lazy var connection: ConnectionType = Connection.cachedInstance
    internal let disposable = CompositeDisposable()
    private var routeDisposable: Disposable?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: Signals

    @available(*, deprecated, message="Use #onDisappear")
    internal lazy var disappear: SignalProducer<(), NoError> = {
        return self.rac_signalForSelector(#selector(UIViewController.viewDidDisappear(_:)))
        .toSignalProducer()
        .map { _ in () }
        .assumeNoError()
    }()

    private lazy var routeSignal: SignalProducer<[Route], ProperError> = {
        return self.connection.call("agency.routes")
            .attemptMap { event -> Result<[AnyObject], ProperError> in
                guard case .Agency(.routes(let routes)) = event else { return .Failure(.eventParseFailure) }
                return .Success(routes)
            }
            .decodeAnyAs(Route.self)
            .on(next: { self.routes = $0; self.tableView.reloadData() },
                failed: self.displayError)
    }()

    private lazy var stationSignal: SignalProducer<[Station], ProperError> = {
        return self.connection.call("agency.stations")
            .attemptMap { event -> Result<[AnyObject], ProperError> in
                guard case .Agency(.stations(let stations)) = event else { return .Failure(.eventParseFailure) }
                return .Success(stations)
            }
            .decodeAnyAs(Station.self)
            .on(next: { self.stations = $0; self.tableView.reloadData() },
                failed: self.displayError)
    }()

    private lazy var vehicleSignal: SignalProducer<[Vehicle], ProperError> = {
        return self.connection.call("agency.vehicles")
            .attemptMap { event -> Result<[AnyObject], ProperError> in
                guard case .Agency(.vehicles(let vehicles)) = event else { return .Failure(.eventParseFailure) }
                return .Success(vehicles)
            }
            .decodeAnyAs(Vehicle.self)
            .on(next: { self.vehicles = $0; self.tableView.reloadData() },
                failed: self.displayError)
    }()

    lazy var pinnedStations: AnyProperty<[Station]> = {
        let pinned = Set(["BUS313NE"])
        let producer = self.stationSignal.map { stations in
            stations.filter { pinned.contains($0.stopCode) }
        }.flatMapError { error in
            return SignalProducer<[Station], NoError>.empty
        }
        return AnyProperty(initialValue: [], producer: producer)
    }()

    // MARK: View events
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start signals to populate the list
        self.routeSignal.start()
        self.stationSignal.start()
        self.vehicleSignal.start()

        self.pinnedStations.producer.startWithNext { _ in
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [pinnedStations.value.count, routes.count, vehicles.count, stations.count][section]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Pinned Stations", "Routes", "Vehicles", "Stations"][section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        
        switch (indexPath.section) {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("PinnedStationPrototypeCell", forIndexPath: indexPath)
            let station = pinnedStations.value[indexPath.row]
            cell!.textLabel?.text = station.name
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("RoutePrototypeCell", forIndexPath: indexPath)
            let route = routes[indexPath.row]
            cell!.textLabel?.text = route.name
        case 2:
            cell = tableView.dequeueReusableCellWithIdentifier("VehiclePrototypeCell", forIndexPath: indexPath)
            let vehicle = vehicles[indexPath.row]
            cell!.textLabel?.text = vehicle.name
        case 3:
            cell = tableView.dequeueReusableCellWithIdentifier("StationPrototypeCell", forIndexPath: indexPath)
            let station = stations[indexPath.row]
            cell!.textLabel?.text = station.name
        default:
            cell = nil
        }

        return cell!
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // A row must be selected to show the arrivals view
        if identifier == "ShowStationView" {
            let row = self.tableView.indexPathForSelectedRow
            return row != nil
        } else {
            return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let id = segue.identifier else { return }
        switch id {
        case "ShowPinnedStation":
            guard let dest = segue.destinationViewController as? StationViewController,
                let index = self.tableView.indexPathForSelectedRow
                else { break }
            let station = self.pinnedStations.value[index.row]
            dest.station = try! MutableStation(from: station, delegate: dest, connection: Connection.cachedInstance)
        case "ShowStationAfterSelectionFromList":
            guard let dest = segue.destinationViewController as? StationViewController,
                let index = self.tableView.indexPathForSelectedRow
                else { break }
            let station = self.stations[index.row]
            dest.station = try! MutableStation(from: station, delegate: dest, connection: Connection.cachedInstance)
        case "ShowRouteAfterSelectionFromList":
            let dest = segue.destinationViewController as! RouteViewController
            let index = self.tableView.indexPathForSelectedRow!
            let route = self.routes[index.row]
            dest.route = try! MutableRoute(from: route, delegate: dest, connection: self.connection)
        default:
            break
        }
    }

}
