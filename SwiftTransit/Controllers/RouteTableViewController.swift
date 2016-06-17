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
    
    func positionVehiclesAtCell(cell: RouteTableViewCell) {
        cell.station.arrivalsAtStation().forEach { arrival in
            positionVehicleForArrival(arrival, atCell: cell)
        }
    }
    
    // Deletes any rail vehicles that no longer correspond to a row in the table.
    func cleanRailVehicles() {
        var del = _vehicles
        var keep = [VehicleViewModel: RailVehicle]()
        for arrival in _arrivals {
            let vehicle = arrival.vehicle
            if let railVehicle = del[vehicle] {
                keep[vehicle] = railVehicle
                del[vehicle] = nil
            }
        }
        // Delete RailVehicles in the del list.
        del.forEach { (vehicle, _) in removeVehicle(vehicle) }
        // RailVehicles in the keep list are the ones that correspond to arrivals the table is showing, they are the new canonical vehicles on the rail.
        _vehicles = keep
    }
    
    // Create or reposition a vehicle dot over the table
    func positionVehicleForArrival(arrival: ArrivalViewModel, atCell cell: RouteTableViewCell) {
        let vehicle = arrival.vehicle
        let (coord, zPos) = calculateRailVehicleForArrival(arrival, atCell: cell)
        // move a vehicle view that's pre-existing, otherwise create one here
        if let stored = _vehicles[vehicle] {
            stored.moveTo(coord)
            stored.layer.zPosition = zPos
        } else {
            let view = RailVehicle(point: coord, arrival: arrival)
            view.layer.zPosition = zPos
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
    
    // Calculate the RailVehicle dot's poistion based on other arrivals at the cell's station
    func calculateRailVehicleForArrival(arrival: ArrivalViewModel, atCell cell: RouteTableViewCell) ->
        (xy: CGPoint, z: CGFloat)
    {
        var point = cell.railtieCoordinates()
        var z = RailVehicle.baseZPosition
        let station = cell.station
        let arrivals = station.arrivalsAtStation().sort(ArrivalViewModel.compareTimes)
        
        // Shift vehicles up and behind vehicles that are arriving sooner
        if let idx = arrivals.map({ $0.vehicle }).indexOf(arrival.vehicle) {
            point.y -= RailVehicle.offset * CGFloat(idx)
            z += CGFloat(arrivals.count - 1 - idx) // sooner vehicles have higher z positions
        }
        return (point, z)
    }
    
    // Fade out a RailVehicle and delete it from the table view and our internal data structures.
    func removeVehicle(vehicle: VehicleViewModel) {
        if let railVehicle = _vehicles[vehicle] {
            UIView.animateWithDuration(0.25,
                animations: {
                    railVehicle.alpha = 0.0
                },
                completion: { _ in
                    railVehicle.removeFromSuperview()
                    self._vehicles[vehicle] = nil
                }
            )
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
        positionVehiclesAtCell(cell)
        
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