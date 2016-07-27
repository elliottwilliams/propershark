//
//  StationTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 7/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class StationArrivalsTableViewController: UITableViewController {

//    var vehicles: MutableProperty<[Vehicle]>
    var station: MutableStation
    let delegate: StationTableViewDelegate

    init(observing station: MutableStation, delegate: StationTableViewDelegate, style: UITableViewStyle) {
        self.station = station
        self.delegate = delegate
        super.init(style: style)
    }

    /// Proper's Storyboard contains the table view that this controller will occupy, so this initializer accepts the
    /// view and initializes the controller with that view's style.
//    convenience init(observing vehicles: [MutableVehicle], delegate: StationTableViewDelegate, view: UITableView) {
//        self.init(observing: vehicles, delegate: delegate, style: view.style)
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Table View Controller Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? { return "Arrivals" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return vehicles.count }
}

protocol StationTableViewDelegate {
    func selectedStation(station: Station, indexPath: NSIndexPath)
}