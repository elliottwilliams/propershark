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
    @IBOutlet weak var routeID: UILabel!
    
    override func viewDidLoad() {
        badge.outerStrokeGap = 5.0
        badge.outerStrokeWidth = 5.0
        badge.capacity = 0.9
        routeID.text = "15"
        self.navigationItem.title = "15 Tower Acres"
    }

}
