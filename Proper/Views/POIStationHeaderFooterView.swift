//
//  POIStationHeaderFooterView.swift
//  Proper
//
//  Created by Elliott Williams on 1/2/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class POIStationHeaderFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    @IBOutlet weak var badgeView: BadgeView!

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

    func apply(station: MutableStation, badge: StationBadge, distance: AnyProperty<String?>) {
        let disposable = CompositeDisposable()

        // Set the badge identifier.
        badgeView.label.text = badge.name
        badgeView.color = badge.color

        // Bind attributes to the UI labels.
        disposable += station.name.producer.startWithNext({ self.title.text = $0 })
        disposable += distance.producer.startWithNext({ distance in
            if let distance = distance {
                self.subtitle.text = "\(station.stopCode) • \(distance) away"
            } else {
                self.subtitle.text = "\(station.stopCode)"
            }
        })

        self.disposable = disposable
    }
}
