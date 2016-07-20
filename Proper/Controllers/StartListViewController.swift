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

    internal lazy var sceneMediator = SceneMediator.sharedInstance
    internal lazy var connection: ConnectionType = Connection.sharedInstance
    internal lazy var config = Config.sharedInstance
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

    private lazy var routeSignal: SignalProducer<[Route], PSError> = {
        return self.connection.call("agency.routes")
            .map { TopicEvent.parseFromRPC("agency.routes", event: $0) }
            .attemptMap { maybeResult -> Result<[AnyObject], PSError> in
                guard let result = maybeResult,
                    case .Agency(.routes(let routes)) = result
                    else { return .Failure(PSError(code: .parseFailure)) }
                return .Success(routes)
            }
            .decodeAnyAs(Route.self)
            .on(next: { self.routes = $0; self.tableView.reloadData() },
                failed: self.displayError)
            .takeUntil(self.onDisappear())
            .logEvents(identifier: "routeSignal", logger: logSignalEvent)
    }()

    private lazy var stationSignal: SignalProducer<[Station], PSError> = {
        return self.connection.call("agency.stations")
            .map { TopicEvent.parseFromRPC("agency.stations", event: $0) }
            .attemptMap { maybeResult -> Result<[AnyObject], PSError> in
                guard let result = maybeResult,
                    case .Agency(.stations(let stations)) = result
                    else { return .Failure(PSError(code: .parseFailure)) }
                return .Success(stations)
            }
            .decodeAnyAs(Station.self)
            .on(next: { self.stations = $0; self.tableView.reloadData() },
                failed: self.displayError)
            .takeUntil(self.onDisappear())
            .logEvents(identifier: "stationSignal", logger: logSignalEvent)
    }()

    private lazy var vehicleSignal: SignalProducer<[Vehicle], PSError> = {
        return self.connection.call("agency.vehicles")
            .map { TopicEvent.parseFromRPC("agency.vehicles", event: $0) }
            .attemptMap { maybeResult -> Result<[AnyObject], PSError> in
                guard let result = maybeResult,
                    case .Agency(.vehicles(let vehicles)) = result
                    else { return .Failure(PSError(code: .parseFailure)) }
                return .Success(vehicles)
            }
            .decodeAnyAs(Vehicle.self)
            .on(next: { self.vehicles = $0; self.tableView.reloadData() },
                failed: self.displayError)
            .takeUntil(self.onDisappear())
            .logEvents(identifier: "vehicleSignal", logger: logSignalEvent)
    }()

    // MARK: View events
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Start signals to populate the list
        self.routeSignal.start()
        self.stationSignal.start()
//        self.vehicleSignal.start()
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [routes.count, vehicles.count, stations.count][section]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Routes", "Vehicles", "Stations"][section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = nil
        
        switch (indexPath.section) {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("RoutePrototypeCell", forIndexPath: indexPath)
            let route = routes[indexPath.row]
            cell!.textLabel?.text = route.name
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("VehiclePrototypeCell", forIndexPath: indexPath)
            let vehicle = vehicles[indexPath.row]
            cell!.textLabel?.text = vehicle.name
        case 2:
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
        case "ShowStationAfterSelectionFromList":
            guard let dest = segue.destinationViewController as? StationViewController,
                let index = self.tableView.indexPathForSelectedRow
                else { break }
            let station = self.stations[index.row]
            dest.station = MutableStation(from: station)
        default:
            break
        }
    }

}