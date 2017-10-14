//
//  ArrivalTableViewCell
//  Proper
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class ArrivalTableViewCell: UITableViewCell {
  @IBOutlet weak var routeTimer: UILabel!
  @IBOutlet weak var routeTitle: UILabel!
  @IBOutlet weak var ornament: UIView!

  var badge: BadgeView!
  var disposable: CompositeDisposable?

  override func awakeFromNib() {
    // Clear ornament background, which is set in IB to make the ornament visible
    self.ornament.backgroundColor = UIColor.clear

    // Create badge programmatically
    let badge = BadgeView(frame: CGRect(x: 8, y: 8, width: 28, height: 28))
    badge.outerStrokeWidth = 0
    badge.outerStrokeGap = 0

    self.ornament.addSubview(badge)
    self.badge = badge
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposable?.dispose()
  }

  deinit {
    disposable?.dispose()
  }

  func apply(arrival: Arrival, route: SignalProducer<MutableRoute, NoError>) {
    self.disposable?.dispose()
    let disposable = CompositeDisposable()

    let badge = Config.shared.map({ $0.agency.badgeForRoute(arrival.route) }).flatten(.latest)
    disposable += badge.producer
      .startWithValues({ self.badge.routeNumber = $0 })

    let title = Config.shared.map({ $0.agency.titleForArrival(arrival) }).flatten(.latest)
    disposable += title.producer
      .startWithValues({ self.routeTitle.text = $0 })

    disposable += route.flatMap(.latest, transform: { $0.color.producer }).skipNil()
      .startWithValues({ self.badge.color = $0 })

    disposable += ArrivalsViewModel.label(for: arrival).startWithValues({ self.routeTimer.text = $0 })
    self.disposable = disposable
  }
}
