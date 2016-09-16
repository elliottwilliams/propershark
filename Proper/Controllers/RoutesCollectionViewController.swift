//
//  RoutesCollectionViewController.swift
//  Proper
//
//  Created by Elliott Williams on 9/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import Dwifft

class RoutesCollectionViewController: UICollectionViewController, ProperViewController {
    var station: MutableStation!

    lazy var routes: AnyProperty<[MutableStation.RouteType]> = {
        let producer = self.station.routes.producer.map { $0.sort() }
        return AnyProperty(initialValue: [], producer: producer)
    }()

    // MARK: Internal properties

    internal var connection: ConnectionType = Connection.sharedInstance
    internal var diffCalculator: CollectionViewDiffCalculator<MutableStation.RouteType>!
    internal var disposable = CompositeDisposable()
    internal var cellBindings = [NSIndexPath: CompositeDisposable]()

    // MARK: Methods

    convenience init(layout: UICollectionViewLayout, station: MutableStation, connection: ConnectionType) {
        self.init(collectionViewLayout: layout)
        self.station = station
        self.connection = connection
    }

    override func viewDidLoad() {
        self.diffCalculator = CollectionViewDiffCalculator(collectionView: self.collectionView!)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        disposable += station.producer.startWithFailed(self.displayError)
        disposable += routes.producer.startWithNext { routes in
            self.diffCalculator.rows = routes
        }
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "showRoute":
            let selected = collectionView!.indexPathsForSelectedItems()!.first!
            let controller = segue.destinationViewController as! RouteViewController
            controller.route = routes.value[selected.row]
        default:
            return
        }
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    // MARK: Delegate methods

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return diffCalculator.rows.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BadgeCell", forIndexPath: indexPath) as! RoutesCollectionViewCell
        let route = routes.value[indexPath.row]

        // Retain a disposable to clear data bindings if this cell is reused.
        let disposable = CompositeDisposable()
        cellBindings[indexPath] = disposable

        // Bind to route attributes.
        disposable += route.color.producer.startWithNext { color in
            _ = color.flatMap { cell.badge.color = $0 }
        }
        cell.badge.routeNumber = route.shortName

        return cell
    }
}
