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
        tableView.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "arrivalCell")

        disposable += viewModel.subscription.startWithResult({ result in
            NSLog("[viewModel.subscription]: \(result)")
            self.tableView.reloadData()
        })
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

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//    }
}
