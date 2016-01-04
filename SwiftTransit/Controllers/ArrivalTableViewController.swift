//
//  ArrivalTableViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ArrivalTableViewController: UITableViewController {
    
    // MARK: Properties
    var _arrivals: [ArrivalViewModel]
    var _delegate: ArrivalTableViewDelegate
    var _title: String
    
    // TODO: Determine if title should just be hardcoded to "Arrivals"
    init(title: String?, arrivals: [ArrivalViewModel], delegate: ArrivalTableViewDelegate, view: UITableView) {
        _title = title ?? "Arrivals"
        _arrivals = arrivals
        _delegate = delegate
        super.init(style: view.style)
        self.view = view // Super establishes view infrastructure, but views are loaded lazily, so setting it after init shouldn't waste resources.
        
        // Register the external xib to be used as a reusable table cell
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _arrivals.count
    }
    
    // There is always one section, titled "Arrivals"
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _title
    }

    // Populate a cell in the arrivals table
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // ArrivalTableViewCell comes from the xib, and is registered upon the creation of this table
        let cell = tableView.dequeueReusableCellWithIdentifier("ArrivalTableViewCell", forIndexPath: indexPath) as! ArrivalTableViewCell

        let arrival = _arrivals[indexPath.row]
        cell.routeTitle.text = arrival.routeName()
        cell.routeTimer.text = arrival.relativeArrivalTime()
        cell.badge.capacity = arrival.vehicleCapacity()

        return cell
    }
    
    // Upon selecting a route stop, show the detail view for that route.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedArrival = _arrivals[indexPath.row]
        _delegate.didSelectArrivalFromArrivalTable(selectedArrival, indexPath: indexPath)
    }

}

// View Controllers that create Arrival Tables should conform to this delegate protocol, which is used by the arrival table to communicate status back to its parent. The parent will be responsible for segueing or otherwise updating the scene based on this state change.
protocol ArrivalTableViewDelegate {
    func didSelectArrivalFromArrivalTable(arrival: ArrivalViewModel, indexPath: NSIndexPath)
}
