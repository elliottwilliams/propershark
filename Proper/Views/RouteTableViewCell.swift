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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // The UIView for this cell is kept outside of the storyboard, for reusability. Load it here, populating `view`.
        // this view.
        let view = NSBundle.mainBundle().loadNibNamed("RouteTableViewCell", owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
    }

    var presenting: RouteStop<MutableStation>? {
        didSet {
            guard let stop = presenting else { return }
            // Bind changes on this station to text
            stop.station.name.map { self.title.text = $0 }
            subtitle.text = stop.station.stopCode

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
