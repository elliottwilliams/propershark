//
//  StationTableViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 8/18/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class StationTableViewCell: UITableViewCell {
    @IBOutlet weak var rail: ScheduleRail!
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    let disposable = CompositeDisposable()

    override func prepareForReuse() {
        disposable.dispose()
        super.prepareForReuse()
    }
}
