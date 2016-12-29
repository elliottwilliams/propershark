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

        disposable += viewModel.subscription.startWithFailed(displayError)
        disposable += viewModel.stations.producer.startWithNext({ stations in
            self.tableView.reloadData()
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
            performSegueWithIdentifier("showStation", sender: viewModel.stations.value[indexPath.section]
                .sortedVehicles.value[indexPath.row-1])
        } else {
            // TODO: show vehicle details
        }
    }
}
