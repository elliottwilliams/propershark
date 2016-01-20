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
    var _stations: [StationViewModel]!
    var _arrivals: [ArrivalViewModel]!
    var _route: RouteViewModel!
    var _title: String
    
    var _vehicles: [VehicleViewModel: RailVehicle] = [:]
    
    init(title: String?, route: RouteViewModel, delegate: RouteTableViewDelegate, view: UITableView) {
        _title = title ?? "Schedule"
        _delegate = delegate
        super.init(style: view.style)
        apply(route)
        self.view = view
        
        // Register the table cell's interface for reuse
        self.tableView.registerNib(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "RouteTableViewCell")
        self.tableView.registerClass(RouteTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "RouteTableFooter")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(route: RouteViewModel) {
        _route = route
        _stations = route.liveStationList()
        _arrivals = route.arrivals
    }
    
    // Create or reposition a vehicle dot over the table
    func positionVehicleForArrival(arrival: ArrivalViewModel, atCell cell: RouteTableViewCell) {
        let vehicle = arrival.vehicle()
        // move a vehicle view that's pre-existing, otherwise create one here
        if let stored = _vehicles[vehicle] {
            stored.moveTo(cell.railtieCoordinates())
        } else {
            let view = RailVehicle(point: cell.railtieCoordinates(), color: arrival.routeColor())
            self.view.addSubview(view)
            _vehicles[vehicle] = view
        }
    }
    func positionVehicleForArrival(arrival: ArrivalViewModel, atStation station: StationViewModel) {
        let cell = self.tableView.visibleCells.filter { ($0 as! RouteTableViewCell).station == station }.first as? RouteTableViewCell // there should only be one
        if cell != nil {
            return positionVehicleForArrival(arrival, atCell: cell!)
        }
    }
    
    func removeVehicle(vehicle: VehicleViewModel) {
        if let view = _vehicles[vehicle] {
            view.removeFromSuperview()
            _vehicles[vehicle] = nil
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _stations.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _title
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("RouteTableViewCell", forIndexPath: indexPath) as! RouteTableViewCell
        
        let station = _stations[indexPath.row]
        cell.apply(station)
        cell.isAnimated = true
        
        // Create vehicles, which are associated with this entry (this station), but not properties of this cell.
        station.arrivalsAtStation().forEach { positionVehicleForArrival($0, atCell: cell) }
        
        return cell
    }
    
    // I feel like this should not be in a view controller :\ perhaps subclass UITableViewHeaderFooterView?
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = self.tableView.dequeueReusableHeaderFooterViewWithIdentifier("RouteTableFooter") as! RouteTableViewHeaderFooterView
        let height = RouteTableViewCell.rowHeightForState(.EmptyStation) // base height off of the empty station row height
        if footer.rail == nil {
            let railView = ScheduleRail(frame: CGRectMake(16.5, 0, height, height)) // TODO: find a way to not hard-code this
            railView.showStation = false
            railView.shape = .NorthWest
            footer.contentView.addSubview(railView)
            footer.rail = railView
        }
        
        return footer
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let station = _stations[indexPath.row]
        let state = RouteTableViewCell.determineStateFromStation(station)
        return RouteTableViewCell.rowHeightForState(state)
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return RouteTableViewCell.rowHeightForState(.EmptyStation)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let station = _stations[indexPath.row]
        let state = RouteTableViewCell.determineStateFromStation(station)
        if state == .VehiclesInTransit {
            // For now, we're not sending this message, in order to make the table easier to use and prevent unintended actions
//            _delegate.didSelectVehicleFromScheduleTable(entry.trips.first!.vehicle, indexPath: indexPath)
        } else {
            _delegate.didSelectStationFromScheduleTable(station, indexPath: indexPath)
        }
    }
    
}

protocol RouteTableViewDelegate {
    func didSelectStationFromScheduleTable(station: StationViewModel, indexPath: NSIndexPath)
    func didSelectVehicleFromScheduleTable(vehicle: VehicleViewModel, indexPath: NSIndexPath)
}