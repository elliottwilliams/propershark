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

    var badge: BadgeView!
    var disposable = CompositeDisposable()

    static var formatter: NSDateComponentsFormatter = {
        let fmt = NSDateComponentsFormatter()
        //fmt.unitsStyle = .Short
        fmt.unitsStyle = .Positional
        //fmt.allowedUnits = [.Minute]
        fmt.allowedUnits = [.Minute, .Second]
        return fmt
    }()

    override func awakeFromNib() {
        // Clear ornament background, which is set in IB to make the ornament visible
        self.ornament.backgroundColor = UIColor.clearColor()
        
        // Create badge programmatically
        let badge = BadgeView(frame: CGRectMake(8, 8, 28, 28))
        badge.outerStrokeWidth = 0
        badge.outerStrokeGap = 0
        
        self.ornament.addSubview(badge)
        self.badge = badge
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposable.dispose()
    }

    deinit {
        disposable.dispose()
    }

    static func timerLabel(arrival: Arrival, state: Arrival.Lifecycle) -> String {
        switch state {
        case .new, .upcoming:
            return formatter.stringFromDate(NSDate(), toDate: arrival.eta) ?? "Upcoming"
        case .due:
            return "Due"
        case .arrived:
            return "Arrived"
        case .departed:
            return "Departed"
        }
    }

    func apply(arrival: Arrival) {
        disposable = CompositeDisposable()
        
        let route = arrival.route
        badge.routeNumber = route.shortName
        badge.color = route.color ?? UIColor.grayColor()
        routeTitle.text = route.name

        disposable += arrival.lifecycle.producer.startWithNext { state in
            self.routeTimer.text = ArrivalTableViewCell.timerLabel(arrival, state: state)
        }
    }
}
