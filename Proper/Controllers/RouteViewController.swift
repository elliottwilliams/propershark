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
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var navItem: TransitNavigationItem!

    // MARK: Internal properties
    internal var connection: ConnectionType = Connection.cachedInstance
    internal let disposable = CompositeDisposable()

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
            self.badge.color = color
            self.badge.strokeColor = contrasting

            // Store the current navigation bar style and adjust color to match route color.
            self.colorNavigationBar(color)
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

        // After transitioning, reset the navigation bar to its default style.
        transitionCoordinator()?.animateAlongsideTransition(nil, completion: { context in
            UIView.animateWithDuration(animated ? 0.2 : 0.0) {
                let vc = context.viewControllerForKey(UITransitionContextToViewControllerKey)
                if let bar = vc?.navigationController?.navigationBar {
                    RouteViewController.resetNavigationBar(bar)
                    bar.layoutIfNeeded()
                }
            }
        })
    }

    override func viewDidDisappear(animated: Bool) {
        disposable.dispose()
        super.viewDidDisappear(animated)
    }

    func colorNavigationBar(color: UIColor) {
        let contrasting = color.blackOrWhiteContrastingColor()
        navigationController?.navigationBar.tintColor = contrasting
        navigationController?.navigationBar.barTintColor = color
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.barStyle = contrasting == UIColor.whiteColor() ? .Black : .Default
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "embedStationTable":
            let table = segue.destinationViewController as! StationTableViewController
            table.route = route
        default:
            return
        }
    }
}
