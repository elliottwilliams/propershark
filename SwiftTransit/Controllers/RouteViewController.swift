//
//  RouteViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteViewController: UIViewController, SceneMediatedController, ArrivalTableViewDelegate {

    @IBOutlet weak var badge: RouteBadge!
    @IBOutlet weak var scheduleTable: UITableView!
    
    var _sceneMediator = SceneMediator.sharedInstance
    var route: RouteViewModel!
    
    override func viewDidLoad() {
        // Configure badge appearence
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.0
        badge.routeNumber = route.routeNumber()
        
        // Set navigation title
        self.navigationItem.title = route.displayName()
        
        // Embed schedule table
        embedScheduleTable()
    }
    
    func embedScheduleTable() {
        let arrivals = Arrival.demoArrivals().map { $0.viewModel() }
        
        let scheduleTable = ArrivalTableViewController(title: "Schedule", arrivals: arrivals, delegate: self, view: self.scheduleTable)
        self.scheduleTable.dataSource = scheduleTable
        self.scheduleTable.delegate = scheduleTable
        
        scheduleTable.willMoveToParentViewController(self)
        self.addChildViewController(scheduleTable)
        scheduleTable.didMoveToParentViewController(self)
        
    }
    
    func didSelectArrivalFromArrivalTable(arrival: ArrivalViewModel, indexPath: NSIndexPath) {
        // Segue to selected station
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}
