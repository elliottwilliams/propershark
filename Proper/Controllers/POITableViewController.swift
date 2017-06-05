//
//  POITableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import Curry
import CoreLocation

class POITableViewController: UITableViewController, ProperViewController {
    typealias Distance = CLLocationDistance

    var stations: Property<[MutableStation]>
    var mapPoint: Property<Point>
    let dataSource = POITableDataSource()

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    static let headerViewHeight = CGFloat(55)

    init(style: UITableViewStyle, stations: Property<[MutableStation]>, mapPoint: Property<Point>) {
        self.stations = stations
        self.mapPoint = mapPoint
        super.init(style: style)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = dataSource
        tableView.register(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "arrivalCell")
        tableView.register(UINib(nibName: "POIStationHeaderFooterView", bundle: nil),
                           forHeaderFooterViewReuseIdentifier: "stationHeader")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns a producer of Ops with side effects added to manipulate the table and data source with changes
    /// described by the table operations. The point where this view's signal chain becomes Very Imperative.
    func modifyTable(producer: SignalProducer<[POIViewModel.Op], ProperError>) ->
        SignalProducer<[POIViewModel.Op], ProperError>
    {
        return producer.on(value: { ops in
            // Iterate through `ops` and record changes made.
            var sectionInsertions = IndexSet()
            var sectionDeletions = IndexSet()
            var rowInsertions = [IndexPath]()
            var rowDeletions = [IndexPath]()

            self.tableView.beginUpdates()
            // Manipulate the data source for each operation.
            ops.forEach { op in
                switch op {
                case let .addStation(station, index: idx):
                    let badge = Badge(alphabetIndex: idx, seedForColor: station)
                    self.dataSource.insert(entry: (station, badge, []), at: idx)
                    sectionInsertions.insert(idx)
                    
                case let .addArrival(arrival, to: station):
                    let path = self.dataSource.indexPath(inserting: arrival, onto: station)
                    rowInsertions.append(path)
                    
                case let .deleteArrival(arrival, from: station):
                    let path = self.dataSource.indexPath(deleting: arrival, from: station)
                    rowDeletions.append(path)

                case let .deleteStation(station, at: idx):
                    self.dataSource.remove(station: station)
                    sectionDeletions.insert(idx)
                    
                case let .reorderStation(_, from: fi, to: ti):
                    self.dataSource.moveStation(from: fi, to: ti)
                    self.tableView.moveSection(fi, toSection: ti)
                }
            }

            let deleted = sectionDeletions.subtracting(sectionInsertions)
            let inserted = sectionInsertions.subtracting(sectionDeletions)
            let reloaded = sectionDeletions.intersection(sectionInsertions)

            // Apply changes to the table.
            self.tableView.deleteRows(at: rowDeletions, with: .top)
            self.tableView.deleteSections(deleted, with: .automatic)
            self.tableView.insertSections(inserted, with: .automatic)
            self.tableView.reloadSections(reloaded, with: .automatic)
            self.tableView.insertRows(at: rowInsertions, with: .bottom)
            self.tableView.endUpdates()
        })
    }

    // MARK: Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Reload a station's section when a topic event is received for it.
        let opsProducer = POIViewModel.chain(connection: connection, producer: stations.producer)
        disposable += modifyTable(producer: opsProducer)
            .logEvents(identifier: "POITableViewController.viewDidAppear", logger: logSignalEvent)
            .startWithFailed(self.displayError)
    }

    override func viewDidDisappear(_ animated: Bool) {
        disposable.dispose()
        super.viewDidDisappear(animated)
    }

    // MARK: Table View Delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return POIViewModel.arrivalRowHeight
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO - show vehicle details upon selection
        // In the meantime, segue to the station.
        parent?.performSegue(withIdentifier: "showStation", sender: dataSource.stations[indexPath.section])
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "stationHeader")
            as! POIStationHeaderFooterView
        let (station, badge, _) = dataSource.table[section]
        let position = station.position.producer.skipNil()
        let distance = POIViewModel.distanceString(mapPoint.producer.combineLatest(with: position))

        header.apply(station: station, badge: badge, distance: distance)
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return POITableViewController.headerViewHeight
    }
}
