//
//  StationTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/14/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Dwifft

class StationTableViewController: UITableViewController, ProperViewController {
    var route: MutableRoute!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.cachedInstance
    internal var diffCalculator: TableViewDiffCalculator<RouteStop<MutableRoute.StationType>>!
    internal let disposable = CompositeDisposable()

    // MARK: Signalled properties
    lazy var stops: Property<[RouteStop<MutableRoute.StationType>]> = {
        let producer = self.route.canonical.producer.skipNil().map { $0.stations }
        return Property(initial: [], then: producer)
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
        disposable += stops.producer.startWithValues { stops in
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
        cell.apply(stop: stops.value[indexPath.row])
        return cell
    }
}
