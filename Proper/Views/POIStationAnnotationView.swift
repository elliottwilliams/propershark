//
//  POIStationAnnotationView.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveCocoa

class POIStationAnnotationView: MKAnnotationView {
    let badge: BadgeView
    private var disposable: CompositeDisposable?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        badge = BadgeView()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        // Configure the badge.
        frame.size = CGSize(width: 25, height: 25)
        badge.frame = bounds
        badge.outerStrokeWidth = 2.0
        addSubview(badge)

        // Configure the callout.
        canShowCallout = true
        rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        disposable?.dispose()
    }

    override func prepareForReuse() {
        self.disposable?.dispose()
    }

    func apply(annotation: POIStationAnnotation) {
        self.disposable?.dispose()
        let disposable = CompositeDisposable()
        self.annotation = annotation
        disposable += annotation.badge.name.producer.startWithNext({ self.badge.label.text = $0 })
        disposable += annotation.badge.color.producer.startWithNext({ self.badge.color = $0 })
        self.disposable = disposable
    }
}
