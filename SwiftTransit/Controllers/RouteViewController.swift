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
        let pairs = route.stationsAlongRouteWithTrips()
        
        _routeTable = RouteTableViewController(title: "Live Route", route: self.route, pairs: pairs, delegate: self, view: self.routeTableView)
        self.routeTableView.dataSource = _routeTable
        self.routeTableView.delegate = _routeTable
        
        _routeTable.willMoveToParentViewController(self)
        self.addChildViewController(_routeTable)
        _routeTable.didMoveToParentViewController(self)
        
    }
    
    func didSelectStationFromScheduleTable(var station: StationViewModel, indexPath: NSIndexPath) {
        // Segue to station. Since StationViewModel is a swift struct, and structs cannot be passed as first-class objects in objc code, encode the struct in an NSData object and pass it along.
        withUnsafePointer(&station) { p in
            let data = NSData(bytes: p, length: sizeofValue(station))
            self.performSegueWithIdentifier("ShowStationFromRouteTable", sender: data)
        }
    }
    
    // TODO: need way to select from one of multiple vehicles
    func didSelectVehicleFromScheduleTable(var vehicle: VehicleViewModel, indexPath: NSIndexPath) {
        // Segue to vehicle. Since VehicleViewModel is a swift struct, and structs cannot be passed as first-class objects in objc code, encode the struct in an NSData object and pass it along.
        withUnsafePointer(&vehicle) { p in
            let data = NSData(bytes: p, length: sizeofValue(vehicle))
            self.performSegueWithIdentifier("ShowVehicleFromRouteTable", sender: data)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

    @IBAction func animateInAction(sender: AnyObject) {
        for cell in _routeTable.tableView.visibleCells.map({ $0 as! RouteTableViewCell }) {
            if cell.rail.showVehicle {
                cell.rail.animatePullDown()
            }
        }
    }
    @IBAction func animateOutAction(sender: AnyObject) {
        let cells = _routeTable.tableView.visibleCells
        for i in 0..<cells.count {
            let cell = cells[i] as! RouteTableViewCell
            if i+1 < cells.count && cell.rail.showVehicle {
                let nextCell = cells[i+1] as! RouteTableViewCell
                let nextCellHeight = _routeTable.tableView(_routeTable.tableView, heightForRowAtIndexPath: NSIndexPath(forRow: i+1, inSection: 0))
                cell.rail.animatePushDownToRailOfShape(nextCell.rail.shape, height: nextCellHeight)
            }
        }
    }
    @IBAction func bothAction(sender: AnyObject) {
        animateInAction(sender)
        animateOutAction(sender)
    }
    @IBAction func advanceVehiclesAction(sender: AnyObject) {
        let trips = route.tripsForRoute().map { $0.withNextStationSelected() }
        let stations = route.stationsAlongRoute()
        let pairs = route.stationsAlongRouteWithTrips(trips, stations: stations)
        let oldPairs = _routeTable._pairs
        _routeTable._pairs = pairs
        
        _routeTable.tableView.beginUpdates()
        let reloadRange = 0..<min(pairs.count, oldPairs.count)
        let reloadPaths = reloadRange.map { NSIndexPath(forRow: $0, inSection: 0) }
        _routeTable.tableView.reloadRowsAtIndexPaths(reloadPaths, withRowAnimation: .Middle)
        
        if oldPairs.count > pairs.count {
            let deleteRange = pairs.count ..< oldPairs.count
            let deletePaths = deleteRange.map { NSIndexPath(forRow: $0, inSection: 0) }
            _routeTable.tableView.deleteRowsAtIndexPaths(deletePaths, withRowAnimation: .Bottom)
        } else if oldPairs.count < pairs.count {
            let insertRange = oldPairs.count ..< pairs.count
            let insertPaths = insertRange.map { NSIndexPath(forRow: $0, inSection: 0) }
            _routeTable.tableView.insertRowsAtIndexPaths(insertPaths, withRowAnimation: .Bottom)
        }
        
        _routeTable.tableView.endUpdates()
    }
}
