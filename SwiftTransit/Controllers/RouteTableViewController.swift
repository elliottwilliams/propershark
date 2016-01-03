//
//  ScheduleTableViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteTableViewController: UITableViewController {
    
    var _delegate: ScheduleTableViewDelegate
    var _route: [TripsForStation]
    var _title: String
    
    init(title: String?, route: [TripsForStation], delegate: ScheduleTableViewDelegate, view: UITableView) {
        _title = title ?? "Schedule"
        _route = route
        _delegate = delegate
        super.init(style: view.style)
        self.view = view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ScheduleTableViewCell")
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
        let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleTableViewCell", forIndexPath: indexPath) as! RouteTableViewCell
        
        // None of this is implemented, but this is how I want to use this interface
        let entry = _route[indexPath.row]
        cell.rail.hasVehicle = entry.hasVehicles()
        cell.rail.hasStation = entry.hasStation()
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

protocol ScheduleTableViewDelegate {
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath)
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath)
}