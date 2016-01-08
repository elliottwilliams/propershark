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
    var _pairs: [JointStationTripViewModel]
    var _route: RouteViewModel
    var _title: String
    
    var _vehicles: [VehicleViewModel: RailVehicle] = [:]
    
    init(title: String?, route: RouteViewModel, pairs: [JointStationTripViewModel], delegate: RouteTableViewDelegate, view: UITableView) {
        _title = title ?? "Schedule"
        _pairs = pairs
        _route = route
        _delegate = delegate
        super.init(style: view.style)
        self.view = view
        
        // Register the table cell's interface for reuse
        self.tableView.registerNib(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "RouteTableViewCell")
        self.tableView.registerClass(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "RouteTableFooter")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _pairs.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("RouteTableViewCell", forIndexPath: indexPath) as! RouteTableViewCell
        
        let entry = _pairs[indexPath.row]
        cell.state = RouteTableViewCell.determineStateForVehicles(entry.hasVehicles(), station: entry.hasStation())!
        cell.accessoryType = (cell.state == .VehiclesInTransit) ? .None : .DisclosureIndicator
        cell.selectionStyle = (cell.state == .VehiclesInTransit) ? .None : .Default
        cell.title.text = entry.displayText()
        cell.subtitle.text = entry.subtitleText()
        cell.rail.vehicleColor = entry.routeColor()
        /*if (entry == _route.first) {
            cell.rail.type = ArrivalTableViewCell.RailTypeWestSouth
        } else if (entry == _route.last) {
            cell.rail.type = ArrivalTableViewCell.RailTypeNorthWest
        } else {
            cell.rail.type = ArrivalTableViewCell.RailTypeNorthSouth
        }*/
        
        // Create vehicle
        for vehicle in entry.vehicles {
            let storedVehicleView = _vehicles[vehicle]
            if storedVehicleView != nil {
                storedVehicleView!.moveTo(cell.railtieCoordinates())
            } else {
                let coords = cell.railtieCoordinates()
                let view = RailVehicle(point: coords, color: entry.routeColor())
                self.view.addSubview(view)
                _vehicles[vehicle] = view
            }
        }
        
        return cell
    }
    
    // I feel like this should not be in a view controller :\ perhaps subclass UITableViewHeaderFooterView?
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = self.tableView.dequeueReusableHeaderFooterViewWithIdentifier("RouteTableFooter")
        let height = RouteTableViewCell.rowHeightForState(.EmptyStation) // base height off of the empty station row height
        let railView = ScheduleRail(frame: CGRectMake(16.5, 0, height, height)) // TODO: find a way to not hard-code this
        railView.showStation = false
        railView.showVehicle = false
        railView.shape = .NorthWest
        footer?.contentView.addSubview(railView)
        
        return footer
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let entry = _pairs[indexPath.row]
        let state = RouteTableViewCell.determineStateForVehicles(entry.hasVehicles(), station: entry.hasStation())!
        return RouteTableViewCell.rowHeightForState(state)
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return RouteTableViewCell.rowHeightForState(.EmptyStation)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let entry = _pairs[indexPath.row]
        let state = RouteTableViewCell.determineStateForVehicles(entry.hasVehicles(), station: entry.hasStation())!
        if state == .VehiclesInTransit {
            // For now, we're not sending this message, in order to make the table easier to use and prevent unintended actions
//            _delegate.didSelectVehicleFromScheduleTable(entry.trips.first!.vehicle, indexPath: indexPath)
        } else {
            _delegate.didSelectStationFromScheduleTable(entry.station!, indexPath: indexPath)
        }
    }
    
}

protocol RouteTableViewDelegate {
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath)
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath)
}