//
//  ArrivalTableViewCell
//  Proper
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ArrivalTableViewCell: UITableViewCell {
    @IBOutlet weak var routeTimer: UILabel!
    @IBOutlet weak var routeTitle: UILabel!
    @IBOutlet weak var ornament: UIView!
    @IBOutlet weak var vehicleName: UILabel!
    
    var badge: RouteBadge!
    var disposable = CompositeDisposable()

    override func awakeFromNib() {
        // Clear ornament background, which is set in IB to make the ornament visible
        self.ornament.backgroundColor = UIColor.clearColor()
        
        // Create badge programmatically
        let badge = RouteBadge(frame: CGRectMake(8, 8, 28, 28))
        badge.outerStrokeWidth = 0
        badge.outerStrokeGap = 0
        
        self.ornament.addSubview(badge)
        self.badge = badge
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func apply(route: MutableRoute) {
        badge.routeNumber = route.shortName
        disposable += route.name.producer.startWithNext { self.routeTitle.text = $0 }
        disposable += route.color.producer.ignoreNil().startWithNext { self.badge.color = $0 }
    }

    func apply(vehicle: MutableVehicle) {
        vehicleName.text = "(Bus #\(vehicle.name))"
        disposable += vehicle.saturation.producer.ignoreNil().startWithNext { self.badge.capacity = CGFloat($0) }
        disposable += vehicle.scheduleDelta.producer.startWithNext { self.routeTimer.text = "∆\($0) min" }
    }
}
