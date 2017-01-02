//
//  BadgeViewViewController.swift
//  Proper
//
//  Created by Elliott Williams on 12/30/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class BadgeViewController: UIViewController {

    override func viewDidLoad() {
        let badge = self.view as! BadgeView
        if let frame = self.view.superview?.frame {
            badge.frame = frame
        }
        badge.calculateDrawingMeasurements()
        badge.drawBadge()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
}
