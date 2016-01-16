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
        let trips = Trip.DemoTrips.filter { $0.route.viewModel() == route }.map { $0.viewModel().withNextStationSelected() }
        let stations = route.stationsAlongRoute()
        
        let old = _routeTable._pairs
        let new = route.stationsAlongRouteWithTrips(trips, stations: stations)
        let changeset = JointStationTripViewModel.deltaFromPairList(old, toList: new)
        _routeTable._pairs = new
        
        if let ch = changeset {
            _routeTable.tableView.beginUpdates()
            let deletable = ch.needsDeletion.map { NSIndexPath(forRow: old.indexOf($0)!, inSection: 0) }
            let insertable = ch.needsInsertion.map { NSIndexPath(forRow: new.indexOf($0)!, inSection: 0) }
            _routeTable.tableView.deleteRowsAtIndexPaths(deletable, withRowAnimation: .Top)
            _routeTable.tableView.insertRowsAtIndexPaths(insertable, withRowAnimation: .Top)
            _routeTable.tableView.endUpdates()
            
//            _routeTable.tableView.visibleCells.forEach { cell in
//                if let cell = cell as? RouteTableViewCell {
//                    if ch.needsReloading.contains(cell.viewModel) {
//                        let newModel =
//                        cell.useViewModel(<#T##model: JointStationTripViewModel##JointStationTripViewModel#>)
//                    }
//                }
//            }
            ch.needsReloading.forEach { entry in
                let path = new.indexOf(entry)
                let cell = _routeTable.tableView.visibleCells[path!] as! RouteTableViewCell
                cell.useViewModel(entry)
            }
        } else {
            // If we have new data but there was no changeset generated, just reload everything. This is a bit of a desparate case that should only happen if the table has been switched to show another entity
            _routeTable.tableView.reloadData()
        }
    }
}
