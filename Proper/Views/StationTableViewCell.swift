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

    func apply(station: MutableStation, withRailShape shape: ScheduleRail.RailShape) {
        disposable.dispose()
        subtitle.text = station.stopCode
        disposable += station.name.producer.startWithNext({ self.title.text = $0 })
        rail.shape = shape
    }

    func apply(stop: RouteStop<MutableStation>) {
        switch stop {
        case .constant(_):
            apply(stop.station, withRailShape: .northSouth)
        case .conditional(_):
            apply(stop.station, withRailShape: .northSouth)
        }
    }
}
