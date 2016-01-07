//
//  RouteViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteViewController: UIViewController, SceneMediatedController, RouteTableViewDelegate {

    @IBOutlet weak var badge: RouteBadge!
    @IBOutlet weak var routeTableView: UITableView!
    
    var _sceneMediator = SceneMediator.sharedInstance
    var route: RouteViewModel!
    var _routeTable: RouteTableViewController!
    
    override func viewDidLoad() {
        // Configure badge appearence
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.0
        badge.routeNumber = route.routeNumber()
        badge.color = route.color
        
        // Set navigation title
        self.navigationItem.title = route.displayName()
        
        // Embed schedule table
        embedScheduleTable()
    }
    
    func embedScheduleTable() {
        let pairs = route.stationsAlongRouteWithTrips(route.tripsForRoute(), stations: route.stationsAlongRoute())
        let model = pairs.map { JointStationTripViewModel(trips: $0.trips, station: $0.station) }
        
        _routeTable = RouteTableViewController(title: "Live Route", route: model, delegate: self, view: self.routeTableView)
        self.routeTableView.dataSource = _routeTable
        self.routeTableView.delegate = _routeTable
        
        _routeTable.willMoveToParentViewController(self)
        self.addChildViewController(_routeTable)
        _routeTable.didMoveToParentViewController(self)
        
    }
    
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath) {
        // Segue to station
        self.performSegueWithIdentifier("ShowStationFromRouteTable", sender: station)
    }
    
    // TODO: need way to select from one of multiple vehicles
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath) {
        // Segue to vehicle
        self.performSegueWithIdentifier("ShowVehicleFromRouteTable", sender: vehicle)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

    @IBAction func animateInAction(sender: UIButton) {
        for cell in _routeTable.tableView.visibleCells.map({ $0 as! RouteTableViewCell }) {
            cell.rail.animateVehicleEntrance()
        }
    }
    @IBAction func animateOutAction(sender: AnyObject) {
        for cell in _routeTable.tableView.visibleCells.map({ $0 as! RouteTableViewCell }) {
            cell.rail.animateVehicleExit()
        }
    }
    @IBAction func toggleVehiclesAction(sender: AnyObject) {
        var previousHadVehicle = false
        for cell in _routeTable.tableView.visibleCells.map({ $0 as! RouteTableViewCell }) {
            let cellHasVehicle = cell.rail.showVehicle
            cell.rail.showVehicle = previousHadVehicle
            previousHadVehicle = cellHasVehicle
        }
    }
}
