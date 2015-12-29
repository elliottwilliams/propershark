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
    
    static var sharedBadge: RouteBadge?
    
    override func viewDidLoad() {
        badge.outerStrokeGap = 0.0
        routeID.text = "15"
        self.navigationItem.title = "15 Tower Acres"
        
        RouteViewController.sharedBadge = badge
    }
}
