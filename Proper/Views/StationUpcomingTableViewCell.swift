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
    let disposable = CompositeDisposable()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Declares `badgeCell` as the reusable cell for the collection view. `RoutesCollectionViewModel` dequeues cells
        // with identifier `badgeCell`.
        collectionView.registerNib(UINib(nibName: "RoutesCollectionBadgeCell", bundle: NSBundle.mainBundle()),
                                   forCellWithReuseIdentifier: "badgeCell")
    }

    override func prepareForReuse() {
        disposable.dispose()
        super.prepareForReuse()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func apply(station: MutableStation) {
        disposable.dispose()

        // Bind station attributes to the UI labels.
        disposable += station.name.producer.startWithNext({ self.title.text = $0 })
        self.subtitle.text = station.stopCode

        let dataSource = RoutesCollectionViewModel(routes: AnyProperty(station.routes))
        collectionView.dataSource = dataSource
        collectionView.reloadData()
    }

}
