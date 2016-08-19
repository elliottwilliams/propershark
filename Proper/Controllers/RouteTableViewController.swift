//
//  RouteTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/14/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft

class RouteTableViewController: UITableViewController, ProperViewController {
    var route: MutableRoute!

    // MARK: UI references
    @IBOutlet var table: UITableView!

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
        diffCalculator = TableViewDiffCalculator(tableView: table, initialRows: stops.value)
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
        let cell = tableView.dequeueReusableCellWithIdentifier("RouteTableViewCell", forIndexPath: indexPath) as! RouteTableViewCell
        let station = stops.value[indexPath.row]

        cell.represents = station
        return cell
    }
}
