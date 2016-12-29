//
//  StationUpcomingCell.swift
//  Proper
//
//  Created by Elliott Williams on 12/29/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

protocol StationUpcomingCell: class {
    // Subviews (implemented as IBOutlets)
    var title: TransitLabel! { get set }
    var subtitle: TransitLabel! { get set }
    var collectionView: UICollectionView! { get set }

    // Internal data structures
    var disposable: CompositeDisposable? { get set }
    var viewModel: RoutesCollectionViewModel? { get set }
    var routes: MutableProperty<Set<MutableRoute>> { get }
}

extension StationUpcomingCell {
    func stationUpcomingCellView() -> UIView! {
        let view = NSBundle.mainBundle().loadNibNamed("StationUpcomingCell", owner: self, options: nil)
        return view![0] as! UIView
    }

    func initStationUpcomingCell() {
        // Declares `badgeCell` as the reusable cell for the collection view. `RoutesCollectionViewModel` dequeues cells
        // with identifier `badgeCell`.
        collectionView.registerNib(UINib(nibName: "RoutesCollectionBadgeCell", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: "badgeCell")

        // Initialize the view model powering the routes collection.
        viewModel = RoutesCollectionViewModel(routes: AnyProperty(routes))
        collectionView.dataSource = viewModel
        collectionView.delegate = viewModel
    }

    func apply(station: MutableStation) {
        let disposable = CompositeDisposable()

        // Bind station attributes to the UI labels.
        disposable += station.name.producer.startWithNext({ self.title.text = $0 })
        self.subtitle.text = station.stopCode

        // As routes are discovered, update the collection view.
        disposable += station.routes.producer.startWithNext({ routes in
            self.routes.swap(routes)
            self.collectionView.reloadData()
        })

        // Subscribe to station events.
        disposable += station.producer.start()
        self.disposable = disposable
    }
}
