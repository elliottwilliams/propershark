//
//  POITableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Dwifft

class POITableViewController: UITableViewController, ProperViewController {
    var viewModel: NearbyStationsViewModel!

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    static let headerViewHeight = CGFloat(55)

    func updateTable(producer: SignalProducer<[(MutableStation, [Arrival])], ProperError>) ->
        SignalProducer<[(MutableStation, [Arrival])], ProperError>
    {
        return producer.combinePrevious([]).on(next: { prev, next in
            let prevStations = prev.map({ st, ar in st })
            let nextStations = next.map({ st, ar in st })

            let diff = prevStations.diff(nextStations)
            let inserts = NSMutableIndexSet()
            let deletes = NSMutableIndexSet()

            diff.results.forEach { step in
                switch step {
                case let .Insert(idx, _):
                    inserts.addIndex(idx)
                case let .Delete(idx, _):
                    deletes.addIndex(idx)
                }
            }
            self.tableView.beginUpdates()
            self.viewModel.model.swap(next)
            self.tableView.insertSections(inserts, withRowAnimation: .Automatic)
            self.tableView.deleteSections(deletes, withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }).map({ $1 })
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = viewModel
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "arrivalCell")
        tableView.registerNib(UINib(nibName: "POIStationHeaderFooterView", bundle: nil),
                              forHeaderFooterViewReuseIdentifier: "stationHeader")
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Reload a station's section when a topic event is received for it.
        disposable += (viewModel.producer |> updateTable)
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
        return NearbyStationsViewModel.arrivalRowHeight
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO - show vehicle details upon selection
        // In the meantime, segue to the station.
        performSegueWithIdentifier("showStation", sender: viewModel.stations.value[indexPath.section])
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("stationHeader")
            as! POIStationHeaderFooterView
        let station = viewModel.stations.value[section]
        let badge = viewModel.badges[station]!
        let distance = viewModel.distances[station]!
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
