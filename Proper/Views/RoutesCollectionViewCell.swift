//
//  RoutesCollectionViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 9/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class RoutesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var badge: RouteBadge!
    var disposable = CompositeDisposable()

    override func awakeFromNib() {
        badge.frame = self.bounds
        setNeedsLayout()
        NSLog("RoutesCollectionViewCell  bounds: \(self.bounds)")
        NSLog("  Badge: bounds: \(badge.bounds)")
    }

    override func prepareForReuse() {
        disposable.dispose()
        super.prepareForReuse()
    }
}
