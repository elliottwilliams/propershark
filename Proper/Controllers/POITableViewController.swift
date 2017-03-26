//
//  POITableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import Curry

class POITableViewController: UITableViewController, ProperViewController {
    typealias Distance = CLLocationDistance

    var stations: AnyProperty<[MutableStation]>!
    var mapPoint: SignalProducer<Point, NoError>!
    let dataSource = POITableDataSource()

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    static let headerViewHeight = CGFloat(55)

    /// Returns a producer of Ops with side effects added to manipulate the table and data source with changes
    /// described by the table operations. The point where this view's signal chain becomes Very Imperative.
    func modifyTable(producer: SignalProducer<POIViewModel.Op, ProperError>) ->
        SignalProducer<POIViewModel.Op, ProperError>
    {
        return producer.on(next: { op in
            self.tableView.beginUpdates()
            switch op {
            case let .addStation(station, index: idx):
                let badge = Badge(alphabetIndex: idx, seedForColor: station)
                self.dataSource.insert((station, badge, []), atIndex: idx)
                self.tableView.insertSections(NSIndexSet(index: idx), withRowAnimation: .Automatic)

            case let .addArrival(arrival, to: station):
                // TODO - Interrupt arrival-finding operations within the view
                // model for stations that are deleted
                guard self.dataSource.indices[station] != nil else { break }
                let path = self.dataSource.indexPathByInserting(arrival, onto: station)
                self.tableView.insertRowsAtIndexPaths([path], withRowAnimation: .Bottom)

            case let .deleteArrival(arrival, from: station):
                // TODO - see .addArrival
                guard self.dataSource.indices[station] != nil else { break }
                let path = self.dataSource.indexPathByDeleting(arrival, from: station)
                self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Top)

            case let .deleteStation(station):
                let idx = self.dataSource.indexByRemoving(station)
                self.tableView.deleteSections(NSIndexSet(index: idx), withRowAnimation: .Automatic)

            case let .reorderStation(_, from: fi, to: ti):
                self.dataSource.moveStation(from: fi, to: ti)
                self.tableView.moveSection(fi, toSection: ti)
            }
            self.tableView.endUpdates()
        })
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "arrivalCell")
        tableView.registerNib(UINib(nibName: "POIStationHeaderFooterView", bundle: nil),
                              forHeaderFooterViewReuseIdentifier: "stationHeader")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Reload a station's section when a topic event is received for it.
        disposable += (POIViewModel.chain(connection, producer: stations.producer) |> modifyTable)
            .logEvents(identifier: "POITableViewController.viewDidAppear", logger: logSignalEvent)
            .startWithFailed(self.displayError)
    }

    override func viewDidDisappear(animated: Bool) {
        disposable.dispose()
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Table View Delegate
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return POIViewModel.arrivalRowHeight
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO - show vehicle details upon selection
        // In the meantime, segue to the station.
        performSegueWithIdentifier("showStation", sender: dataSource.stations[indexPath.section])
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("stationHeader")
            as! POIStationHeaderFooterView
        let (station, badge, _) = dataSource.table[section]
        let distance = POIViewModel.distanceString(combineLatest(mapPoint, station.position.producer.ignoreNil()))

        header.apply(station, badge: badge, distance: distance)
        return header
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return POITableViewController.headerViewHeight
    }

    // MARK: Segue management
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "showStation":
            let station = sender as! MutableStation
            let dest = segue.destinationViewController as! StationViewController
            dest.station = station
        default:
            return
        }
    }
}
