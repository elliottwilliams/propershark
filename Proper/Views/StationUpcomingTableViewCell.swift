//
//  StationUpcomingTableViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 12/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class StationUpcomingTableViewCell: UITableViewCell {
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    @IBOutlet weak var collectionView: UICollectionView!

    var disposable: CompositeDisposable?
    var viewModel: RoutesCollectionViewModel?
    let routes = MutableProperty<Set<MutableRoute>>(Set())

    deinit {
        disposable?.dispose()
    }

    override func prepareForReuse() {
        disposable?.dispose()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
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
