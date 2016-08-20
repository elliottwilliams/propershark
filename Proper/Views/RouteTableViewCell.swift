//
//  RouteTableViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 8/18/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var rail: ScheduleRail!
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!

    var represents: RouteStop<MutableStation>? {
        didSet {
            guard let stop = self.represents else { return }

            // Bind changes on this station to text
            stop.station.name.map { self.title.text = $0 }

            // Handle differences between stop types
            switch stop {
            case .constant(_):
                rail.shape = .NorthSouth
            case .conditional(_):
                // TODO: render as a conditional station
                rail.shape = .NorthSouth
            }
        }
    }
}
