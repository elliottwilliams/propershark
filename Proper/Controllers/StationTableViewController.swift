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
    internal var connection: ConnectionType = Connection.cachedInstance
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
        tableView.register(UINib(nibName: "StationTableViewCell", bundle: nil), forCellReuseIdentifier: "stationCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Subscribe to route updates.
        disposable += route.producer.startWithFailed(self.displayError)
        disposable += stops.producer.startWithNext { stops in
            self.diffCalculator.rows = stops
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    // MARK: Delegate methods
    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return "Stops" }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return stops.value.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stationCell", for: indexPath)
            as! StationTableViewCell
        cell.apply(stops.value[indexPath.row])
        return cell
    }
}
