//
//  RouteViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class RouteViewController: UIViewController, ProperViewController, MutableModelDelegate, UINavigationBarDelegate {

    var route: MutableRoute!

    // MARK: UI references
    @IBOutlet weak var badge: RouteBadge!
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var navBar: UINavigationBar!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.sharedInstance
    internal let contrastingColor = MutableProperty<UIColor?>(nil)
    internal let disposable = CompositeDisposable()
    internal let navItem: UINavigationItem = TransitNavigationItem()

    // MARK: Methods
    override func viewDidLoad() {
        // Configure the route badge.
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 1.0
    }

    override func viewWillAppear(animated: Bool) {
        // Bind route data.
        badge.routeNumber = route.shortName
        disposable += route.color.producer.ignoreNil().startWithNext { color in
            let contrasting = color.blackOrWhiteContrastingColor()
            self.contrastingColor.swap(contrasting)
            self.badge.color = color
            self.badge.strokeColor = contrasting

            // Store the current navigation bar style and adjust color to match route color.
            self.styleNavigationBar()
            self.infoContainer.backgroundColor = color
        }
        disposable += route.name.producer.ignoreNil().startWithNext { name in
            self.navItem.title = name
        }

        // Begin requesting route data.
        disposable += route.producer.startWithFailed(self.displayError)

        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let color = route.color.value {
            colorNavigationBar(color)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore navigation bar
        navigationController?.navigationBar.barStyle = .Default
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(animated: Bool) {
        disposable.dispose()
        super.viewDidDisappear(animated)
    }

    override func viewWillAppear(animated: Bool) {
        // Hide the global navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // Use the state of the global navigation bar to form the "back" item in our custom navigation bar.
        if let prevItem = navigationController?.navigationBar.topItem {
            navBar.pushNavigationItem(UINavigationItem(title: prevItem.title ?? "Back"), animated: animated)
        }

        // Add the route's navigation item to the bar, and style the bar appropriately.
        navBar.pushNavigationItem(navItem, animated: animated)
        styleNavigationBar()
    }

    func styleNavigationBar() {
        guard let color = route.color.value, let contrasting = contrastingColor.value else {
            return
        }

        navBar.tintColor = contrasting
        navBar.barTintColor = color

        let barStyle = contrasting == UIColor.whiteColor() ? UIBarStyle.Black : UIBarStyle.Default
        navBar.barStyle = barStyle
        navigationController?.navigationBar.barStyle = barStyle
    }

    func navigationBar(navigationBar: UINavigationBar, shouldPopItem item: UINavigationItem) -> Bool {
        if item == navItem {
            navigationController?.popViewControllerAnimated(true)
            return false
        } else {
            return true
        }
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
