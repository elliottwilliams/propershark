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
    lazy var sceneMediator = SceneMediator.sharedInstance
    lazy var connection = Connection.sharedInstance
    lazy var config = Config.sharedInstance
    private var routeDisposable: Disposable?
    
    init(mediator: SceneMediator = .sharedInstance, connection: Connection = .sharedInstance, style: UITableViewStyle) {
        super.init(style: style)
        self.sceneMediator = mediator
        self.connection = connection
    }
    
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
        self.routeDisposable = self.connection.call(topic, args: [], kwargs: [:])
        .map() { wampResult in RPCResult.parseFromTopic(topic, event: wampResult) }
        .attemptMap() { (maybeResult) -> Result<[Route], PSError> in
            guard let result = maybeResult,
                case .Agency(.routes(let objects)) = result
                else { return .Failure(PSError(code: .parseFailure)) }
            
            let routes = objects.map { decode($0) as Route? }.flatMap() { $0 }
            if routes.count == 0 {
                return .Failure(PSError(code: .parseFailure))
            }
            
            return .Success(routes)
        }
        .on(
            next: { routes in self.routes = routes },
            failed: { error in self.presentViewController(error.alert, animated: true, completion: nil)
            }
        )
        .start()

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