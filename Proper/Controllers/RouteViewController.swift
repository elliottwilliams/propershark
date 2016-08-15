//
//  RouteViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class RouteViewController: UIViewController, ProperViewController, MutableModelDelegate {

    var route: MutableRoute!

    // MARK: UI references
    @IBOutlet weak var badge: RouteBadge!
    @IBOutlet weak var nav: UINavigationItem!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.sharedInstance
    internal let disposable = CompositeDisposable()

    // MARK: Methods
    override func viewDidLoad() {
        // Bind route data
        disposable += route.producer.startWithFailed(self.displayError)
        badge.routeNumber = route.shortName
        route.color.map { self.badge.color = $0 ?? Config.ui.defaultBadgeColor }
        route.name.map { self.nav.title = $0 }

        // Configure the route badge
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.0
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "embedRouteTable":
            let table = segue.destinationViewController as! RouteTableViewController
            table.route = route
        default:
            return
        }
    }
}
