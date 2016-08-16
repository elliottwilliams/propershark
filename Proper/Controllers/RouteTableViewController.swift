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

    // MARK: Methods
    override func viewDidLoad() {
        // Subscribe to route updates.
        disposable += route.producer.startWithFailed(self.displayError)

        diffCalculator = TableViewDiffCalculator(tableView: table, initialRows: route.canonical.value?.stations ?? [])

        table.registerNib(UINib(nibName: "RouteTableViewCell", bundle: nil), forCellReuseIdentifier: "RouteTableViewCell")
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
    }
}
