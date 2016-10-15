//
//  StationTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/14/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft

class StationTableViewController: UITableViewController, ProperViewController {
    var route: MutableRoute!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.sharedInstance
    internal var diffCalculator: TableViewDiffCalculator<RouteStop<MutableRoute.StationType>>!
    internal let disposable = CompositeDisposable()

    // MARK: Signalled properties
    lazy var stops: AnyProperty<[RouteStop<MutableRoute.StationType>]> = {
        let producer = self.route.canonical.producer.ignoreNil().map { $0.stations }
        return AnyProperty(initialValue: [], producer: producer)
    }()

    // MARK: Methods
    override func viewDidLoad() {
        diffCalculator = TableViewDiffCalculator(tableView: tableView, initialRows: stops.value)
//        tableView.registerNib(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "StationTableViewCell")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Subscribe to route updates.
        disposable += route.producer.startWithFailed(self.displayError)
        disposable += stops.producer.startWithNext { stops in
            self.diffCalculator.rows = stops
        }
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    // MARK: Delegate methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return "Stops" }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return stops.value.count }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PrototypeCell", forIndexPath: indexPath) as! StationTableViewCell
        let stop = stops.value[indexPath.row]

        cell.disposable += stop.station.name.producer.startWithNext { cell.title.text = $0 }
        cell.subtitle.text = stop.station.stopCode
        switch stop {
        case .constant(_):
            cell.rail.shape = .NorthSouth
        case .conditional(_):
            cell.rail.shape = .NorthSouth
        }

        return cell
    }
}
