//
//  RouteTableViewCell.swift
//  Proper
//
//  Created by Elliott Williams on 8/18/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class RouteTableViewCell: UITableViewCell {
    @IBOutlet weak var rail: ScheduleRail!
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    let disposable = CompositeDisposable()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // The UIView for this cell is kept outside of the storyboard, for reusability. Load it here, populating `view`.
        let view = NSBundle.mainBundle().loadNibNamed("RouteTableViewCell", owner: self, options: nil)![0] as! UIView
        self.addSubview(view)
    }

    override func prepareForReuse() {
        disposable.dispose()
        super.prepareForReuse()
    }
}
