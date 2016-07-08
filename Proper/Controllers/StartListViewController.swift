//
//  StartListViewController.swift
//  Proper
//
//  Created by Elliott Williams on 12/24/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import Argo

class StartListViewController: UITableViewController/*, SceneMediatedController*/ {
    
    // MARK: - Properties
    var routes: [Route] = []
    private lazy var sceneMediator = SceneMediator.sharedInstance
    private lazy var connection: ConnectionType = Connection.sharedInstance
    private lazy var config = Config.sharedInstance
    private var routeDisposable: Disposable?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View events
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let topic = "agency.routes"
        let signalProducer =
            self.connection.call(topic, args: [], kwargs: [:])
            .map() { wampResult in RPCResult.parseFromTopic(topic, event: wampResult) }
            // TODO I'd like to make part of this a signal operator. Signal consumer needs to do event parsing, but there can be an operator that takes AnyObject and a Decodable type and returns a Result like it's done here. This would reduce this operator from 18 lines to 5.
            .attemptMap() { maybeResult -> Result<[Route], PSError> in
                guard let result = maybeResult,
                    case .Agency(.routes(let body)) = result,
                    // The body of this request is a list of list of routes.
                    let objects = (body as? [AnyObject])?.first,
                    let list = objects as? [AnyObject]
                    else { return .Failure(PSError(code: .parseFailure)) }
                
                // Decode the list of routes. If any in the list were decoded, success with those.
                // Otherwise, fail with a list of decoder errors.
                let decoded = list.map { decode($0) as Decoded<Route> }
                let errors = decoded.map { $0.error }
                let routes = decoded.flatMap { $0.value }
                if !routes.isEmpty {
                    return .Success(routes)
                } else {
                    return .Failure(PSError(code: .parseFailure, associated: errors))
                }
            }
            .on(
                next: { routes in
                    self.routes = routes
                    // Quick and dirty table reload. To do anything more sophisticated is going to take a ViewModel/MutableModel
                    self.tableView.reloadData()
                },
                failed: { error in
                    self.presentViewController(error.alert as UIViewController, animated: true, completion: nil)
                }
            )
        self.routeDisposable = signalProducer.start()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.routeDisposable?.dispose()
        
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return [routes.count, vehicles.count, stations.count][section]
        return [routes.count][section]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Routes"][section]
//        return ["Routes", "Vehicles", "Stations"][section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = nil
        
        switch (indexPath.section) {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("RoutePrototypeCell", forIndexPath: indexPath)
            let route = routes[indexPath.row]
            cell!.textLabel?.text = route.name
//        case 1:
//            cell = tableView.dequeueReusableCellWithIdentifier("VehiclePrototypeCell", forIndexPath: indexPath)
//            let vehicle = vehicles[indexPath.row]
//            cell!.textLabel?.text = vehicle.name
//        case 2:
//            cell = tableView.dequeueReusableCellWithIdentifier("StationPrototypeCell", forIndexPath: indexPath)
//            let station = stations[indexPath.row]
//            cell!.textLabel?.text = station.name
        default:
            cell = nil
        }

        return cell!
    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // A row must be selected to show the arrivals view
        if identifier == "ShowStationView" {
            let row = self.tableView.indexPathForSelectedRow
            return row != nil
        } else {
            return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}