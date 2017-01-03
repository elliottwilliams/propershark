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

    func apply(annotation: POIStationAnnotation) {
        self.annotation = annotation
        badge.label.text = annotation.badge.name
        badge.color = annotation.badge.color
    }
}
