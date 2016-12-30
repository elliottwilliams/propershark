//
//  POITableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class POITableViewController: UITableViewController, ProperViewController {

    var point: AnyProperty<Point>!
    var viewModel: NearbyStationsViewModel!

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = NearbyStationsViewModel(point: point, connection: connection)
        tableView.dataSource = viewModel
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "arrivalCell")
        tableView.registerNib(UINib(nibName: "StationUpcomingTableViewCell", bundle: nil),
                              forCellReuseIdentifier: "stationCell")

        // From the list of stations coming from the view model, produce topic event subscriptions for each station.
        // Pass the station's index through, and reload a station's section when a topic event is received for it.
        disposable += viewModel.producer.map({ $0.enumerate() })
        .flatMap(.Latest, transform: { stations in
            // Map an enumerated list of stations to individual station-idx pairs.
            return SignalProducer<(Int, MutableStation), ProperError>(values: stations)
        }).flatMap(.Merge, transform: { idx, station -> SignalProducer<(Int, TopicEvent), ProperError> in
            // Map station-idx pairs to event producer-idx pairs.
            return SignalProducer(value: idx).combineLatestWith(station.producer)
        }).startWithResult({ result in
            switch result {
            case let .Success(idx, _):
//                let sections = NSIndexSet(index: idx)
//                self.tableView.reloadSections(sections, withRowAnimation: .Automatic)
                self.tableView.reloadData()
            case let .Failure(error):
                self.displayError(error)
            }
        })
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
