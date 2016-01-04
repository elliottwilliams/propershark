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
    @IBOutlet weak var scheduleTable: UITableView!
    
    var _sceneMediator = SceneMediator.sharedInstance
    var route: RouteViewModel!
    
    override func viewDidLoad() {
        // Configure badge appearence
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.0
        badge.routeNumber = route.routeNumber()
        
        // Set navigation title
        self.navigationItem.title = route.displayName()
        
        // Embed schedule table
        embedScheduleTable()
    }
    
    func embedScheduleTable() {
        let pairs = route.stationsAlongRouteWithTrips(route.tripsForRoute(), stations: route.stationsAlongRoute())
        let model = pairs.map { JointStationTripViewModel(trips: $0.trips, station: $0.station) }
        
        let scheduleTable = RouteTableViewController(title: "Live Route", route: model, delegate: self, view: self.scheduleTable)
        self.scheduleTable.dataSource = scheduleTable
        self.scheduleTable.delegate = scheduleTable
        
        scheduleTable.willMoveToParentViewController(self)
        self.addChildViewController(scheduleTable)
        scheduleTable.didMoveToParentViewController(self)
        
    }
    
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath) {
        // Segue to station
        self.performSegueWithIdentifier("ShowStationFromRouteTable", sender: station)
    }
    
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath) {
        // Segue to vehicle
        self.performSegueWithIdentifier("ShowVehicleFromRouteTable", sender: vehicle)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}
