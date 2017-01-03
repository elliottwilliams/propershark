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

    func followSectionChanges(producer: SignalProducer<[MutableStation], ProperError>) ->
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

    func followRowChanges(producer: SignalProducer<[MutableStation], ProperError>) ->
        SignalProducer<TopicEvent, ProperError>
    {
        return producer.flatMap(.Latest, transform: { stations ->
            SignalProducer<SignalProducer<(TopicEvent, Int), ProperError>, ProperError> in

            // Produce (station, section idx) pairs...
            return SignalProducer(values: stations.enumerate().map({ idx, station in
                // ...then extract the station's event producer. Combine all received events with the section idx.
                station.producer.combineLatestWith(SignalProducer(value: idx))
            }))
        // Flatten the producer of topic event producers to all the topic events for the latest set of stations,
        // merged together.
        }).flatten(.Merge).on(next: { event, idx in
            // Use the section index numbers to reload sections as events are received within them.
            if case .Station(.update(let station, _)) = event {
                assert(self.viewModel.stations.value[idx].identifier == station.value?.identifier,
                    "Event received doesn't belong to the section at index \(idx)")
            }
            self.tableView.reloadSections(NSIndexSet(index: idx), withRowAnimation: .Automatic)
        }).map({ station, _ in station })
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = viewModel
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "arrivalCell")
        tableView.registerNib(UINib(nibName: "POIStationHeaderFooterView", bundle: nil),
                              forHeaderFooterViewReuseIdentifier: "stationHeader")

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Reload a station's section when a topic event is received for it.
        disposable += (viewModel.producer |> followSectionChanges |> followRowChanges)
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
