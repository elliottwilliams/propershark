//
//  StartListViewController.swift
//  Proper
//
//  Created by Elliott Williams on 12/24/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class StartListViewController: UITableViewController, SceneMediatedController {
    
    // MARK: - Properties
    
    let routes = Route.DemoRoutes
    let vehicles = Vehicle.DemoVehicles
    let stations = Station.DemoStations
    
    var _sceneMediator = SceneMediator.sharedInstance
        
    override func viewDidLoad() {
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
            let routeView = RouteViewModel(route)
            cell!.textLabel?.text = routeView.displayName()
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
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}