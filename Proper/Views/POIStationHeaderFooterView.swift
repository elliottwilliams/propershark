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

  var disposable: CompositeDisposable?
  var color: UIColor? {
    get { return self.contentView.backgroundColor }
    set { self.contentView.backgroundColor = newValue }
  }

  deinit {
    disposable?.dispose()
  }

  override func awakeFromNib() {
    contentView.backgroundColor = UIColor.clear
  }

  override func prepareForReuse() {
    disposable?.dispose()
  }

  func apply(station: MutableStation, distance: SignalProducer<String, NoError>) {
    self.disposable?.dispose()
    let disposable = CompositeDisposable()

    // Bind station attributes...
    disposable += station.name.producer.startWithValues({ self.title.text = $0 })
    self.subtitle.text = "\(station.stopCode)"
    // ...and distance string.
    disposable += distance.producer.startWithValues({ distance in
      self.subtitle.text = "\(station.stopCode) • \(distance) away"
    })

    self.disposable = disposable
  }
}
