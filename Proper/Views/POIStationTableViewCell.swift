//
//  POIStationTableViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 1/2/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class POIStationTableViewCell: UITableViewCell {
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    @IBOutlet weak var badge: RouteBadge!

    var disposable: CompositeDisposable?

    deinit {
        disposable?.dispose()
    }

//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }

    override func prepareForReuse() {
        disposable?.dispose()
    }

    func apply(station: MutableStation, badgeIdentifier: String) {
        let disposable = CompositeDisposable()

        // Set the badge identifier.
        badge.label.text = badgeIdentifier

        // Bind station attributes to the UI labels.
        disposable += station.name.producer.startWithNext({ self.title.text = $0 })
        self.subtitle.text = station.stopCode

        self.disposable = disposable
    }
}
