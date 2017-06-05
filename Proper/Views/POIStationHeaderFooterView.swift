//
//  POIStationHeaderFooterView.swift
//  Proper
//
//  Created by Elliott Williams on 1/2/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class POIStationHeaderFooterView: UITableViewHeaderFooterView {
  @IBOutlet weak var title: TransitLabel!
  @IBOutlet weak var subtitle: TransitLabel!
  @IBOutlet weak var badgeView: BadgeView!

  var disposable: CompositeDisposable?

  deinit {
    disposable?.dispose()
  }

  override func awakeFromNib() {
    contentView.backgroundColor = UIColor.clear
    badgeView.color = UIColor.clear
  }

  override func prepareForReuse() {
    disposable?.dispose()
  }

  func apply(station: MutableStation, badge: Badge, distance: SignalProducer<String, NoError>) {
    self.disposable?.dispose()
    let disposable = CompositeDisposable()

    // Bind station attributes...
    disposable += station.name.producer.startWithValues({ self.title.text = $0 })
    self.subtitle.text = "\(station.stopCode)"
    // ...badges...
    disposable += badge.name.producer.startWithValues({ self.badgeView.label.text = $0 })
    disposable += badge.color.producer.startWithValues({ self.contentView.backgroundColor = $0 })
    // ...and distance string.
    disposable += distance.producer.startWithValues({ distance in
      self.subtitle.text = "\(station.stopCode) • \(distance) away"
    })

    self.disposable = disposable
  }
}
