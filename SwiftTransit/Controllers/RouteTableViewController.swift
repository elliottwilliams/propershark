//
//  ScheduleTableViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteTableViewController: UITableViewController {
    
    var _delegate: RouteTableViewDelegate
    var _route: [JointStationTripViewModel]
    var _title: String
    
    init(title: String?, route: [JointStationTripViewModel], delegate: RouteTableViewDelegate, view: UITableView) {
        _title = title ?? "Schedule"
        _route = route
        _delegate = delegate
        super.init(style: view.style)
        self.view = view
        
        // Register the table cell's interface for reuse
        tableView.registerNib(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "RouteTableViewCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _route.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RouteTableViewCell", forIndexPath: indexPath) as! RouteTableViewCell
        
        // None of this is implemented, but this is how I want to use this interface
        let entry = _route[indexPath.row]
        if entry.hasVehicles() && !entry.hasStation() {
            cell.state = .VehiclesInTransit
        } else if !entry.hasVehicles() && entry.hasStation() {
            cell.state = .EmptyStation
        } else if entry.hasVehicles() && entry.hasStation() {
            cell.state = .VehiclesAtStation
        }
        cell.title.text = entry.displayText()
        cell.subtitle.text = entry.subtitleText()
        /*if (entry == _route.first) {
            cell.rail.type = ArrivalTableViewCell.RailTypeWestSouth
        } else if (entry == _route.last) {
            cell.rail.type = ArrivalTableViewCell.RailTypeNorthWest
        } else {
            cell.rail.type = ArrivalTableViewCell.RailTypeNorthSouth
        }*/
        
        return cell
    }

}

protocol RouteTableViewDelegate {
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath)
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath)
}