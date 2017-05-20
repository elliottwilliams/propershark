//
//  RoutesCollectionViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 9/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift

class RoutesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var badge: BadgeView!
    var disposable = CompositeDisposable()

    override func awakeFromNib() {
        badge.frame = self.bounds
        setNeedsLayout()
    }

    override func prepareForReuse() {
        disposable.dispose()
        super.prepareForReuse()
    }

    func apply(route: MutableRoute) {
        disposable += route.color.producer.startWithValues { color in
            _ = color.flatMap { self.badge.color = $0 }
        }
        badge.routeNumber = route.shortName
    }
}
