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

    func updateViewModel(producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<[MutableStation], ProperError>
    {
        return producer.combinePrevious([]).on(next: { prev, next in
            let diff = prev.diff(next)
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
            self.viewModel.stations.swap(next)
            self.tableView.insertSections(inserts, withRowAnimation: .Automatic)
            self.tableView.deleteSections(deletes, withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }).map({ $1 })
    }

    func reloadChangedSections(producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<MutableStation, ProperError>
    {
        return producer.map({ $0.enumerate() })
            .flatMap(.Latest, transform: { stations in
                return SignalProducer<(Int, MutableStation), ProperError>(values: stations)
            }).on(next: { idx, _ in
                self.tableView.reloadSections(NSIndexSet(index: idx), withRowAnimation: .Automatic)
            }).map({ $1 })
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = viewModel
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "arrivalCell")
        tableView.registerNib(UINib(nibName: "StationUpcomingTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "stationCell")

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Reload a station's section when a topic event is received for it.
        disposable += (viewModel.producer |> updateViewModel |> reloadChangedSections)
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
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.row == 0 ? NearbyStationsViewModel.stationRowHeight : NearbyStationsViewModel.arrivalRowHeight
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            performSegueWithIdentifier("showStation", sender: viewModel.stations.value[indexPath.section])
        } else {
            // TODO: show vehicle details upon selection
        }
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
