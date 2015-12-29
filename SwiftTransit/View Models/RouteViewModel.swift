//
//  RouteViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteViewModel: NSObject {
    var route: Route
    init(route: Route) {
        self.route = route
    }
    
    func fullName() -> String {
        return "\(route.id) \(route.name)"
    }
}
