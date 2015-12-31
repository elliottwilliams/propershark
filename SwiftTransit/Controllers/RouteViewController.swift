//
//  RouteViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteViewController: UIViewController/*, SceneMediatedController*/ {

    @IBOutlet weak var badge: RouteBadge!
    
    override func viewDidLoad() {
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.9
        badge.routeNumber = "99"
        self.navigationItem.title = "15 Tower Acres"
    }

}
