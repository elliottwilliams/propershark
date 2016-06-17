//
//  RouteViewController.swift
//  Proper
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
    
    // MARK: Bootstrap
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("yo")
    }
    
    override func viewDidLoad() {
        // Configure badge appearence
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.0
        badge.routeNumber = route.routeNumber()
        badge.color = route.color
        
        // Set navigation title
        self.navigationItem.title = route.displayName()
        
        // Update view model by fetching trip data
        updateViewModel()
        
        // Embed schedule table
        embedScheduleTable()
    }
    
    func updateViewModel() {
        let arrivals = Arrival.demoArrivals().map { $0.viewModel() }
        self.route = self.route.withArrivals(arrivals)
    }
    
    func embedScheduleTable() {
        _routeTable = RouteTableViewController(title: "Live Route", route: self.route, delegate: self, view: self.routeTableView)
        self.routeTableView.dataSource = _routeTable
        self.routeTableView.delegate = _routeTable
        
        _routeTable.willMoveToParentViewController(self)
        self.addChildViewController(_routeTable)
        _routeTable.didMoveToParentViewController(self)
        
    }
    
    // MARK: Delegated actions
    
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
    
    // MARK: Triggered actions

    @IBAction func advanceVehiclesAction(sender: AnyObject) {
        
        // Advance all arrivals to the next station, and update the route this view is representing.
        let old = self.route.liveStationList()
        let arrivals = self.route.arrivals.map { $0.withAdvancedStation() }
        self.route = self.route.withArrivals(arrivals)
        let new = self.route.liveStationList()
        
        // Calculate changes made to the live list, which will be reflected in the table
        let changeset = StationViewModel.changesFrom(old, to: new)
        
        // Commit these changes to the table
        _routeTable.apply(self.route) // TODO: perhaps a lot of this method's functionality can be moved into apply()
        _routeTable.tableView.beginUpdates()
        let deletable = changeset.deleted.map { NSIndexPath(forRow: old.indexOf($0)!, inSection: 0) }
        let insertable = changeset.inserted.map { NSIndexPath(forRow: new.indexOf($0)!, inSection: 0) }
        _routeTable.tableView.deleteRowsAtIndexPaths(deletable, withRowAnimation: .Top)
        _routeTable.tableView.insertRowsAtIndexPaths(insertable, withRowAnimation: .Top)
        _routeTable.tableView.endUpdates()
        
        // Update view models and vehicle positions for cells that are persisting
        changeset.persisted.forEach { station in
            let path = new.indexOf(station)
            let cell = _routeTable.tableView.visibleCells[path!] as! RouteTableViewCell
            cell.apply(station)
            _routeTable.positionVehiclesAtCell(cell)
        }
        
        // Delete any left behind vehicle dots
        _routeTable.cleanRailVehicles()
    }
}
