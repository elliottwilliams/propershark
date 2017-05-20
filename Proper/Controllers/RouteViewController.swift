//
//  RouteViewController.swift
//  Proper
//
//  Created by Elliott Williams on 8/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class RouteViewController: UIViewController, ProperViewController {

    var route: MutableRoute!

    // MARK: UI references
    @IBOutlet weak var badge: BadgeView!
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

        // Bind route data.
        badge.routeNumber = route.shortName
        disposable += route.color.producer.skipNil().startWithValues { color in
            let contrasting = color.blackOrWhiteContrastingColor()
            self.badge.color = color
            self.badge.strokeColor = contrasting

            // Store the current navigation bar style and adjust color to match route color.
            self.colorNavigationBar(color)
            self.infoContainer.backgroundColor = color
        }
        disposable += route.name.producer.skipNil().startWithValues { name in
            self.navItem.title = name
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        // Begin requesting route data.
        disposable += route.producer.startWithFailed(self.displayError)

        super.viewDidAppear(animated)
        if let color = route.color.value {
            colorNavigationBar(color)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // After transitioning, reset the navigation bar to its default style.
        transitionCoordinator?.animate(alongsideTransition: nil, completion: { context in
            UIView.animate(withDuration: animated ? 0.2 : 0.0, animations: {
                let vc = context.viewController(forKey: UITransitionContextViewControllerKey.to)
                if let bar = vc?.navigationController?.navigationBar {
                    RouteViewController.resetNavigationBar(bar)
                    bar.layoutIfNeeded()
                }
            }) 
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        disposable.dispose()
        super.viewDidDisappear(animated)
    }

    func colorNavigationBar(_ color: UIColor) {
        let contrasting = color.blackOrWhiteContrastingColor()
        navigationController?.navigationBar.tintColor = contrasting
        navigationController?.navigationBar.barTintColor = color
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.barStyle = contrasting == UIColor.white ? .black : .default
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "embedStationTable":
            let table = segue.destination as! StationTableViewController
            table.route = route
        default:
            return
        }
    }
}
