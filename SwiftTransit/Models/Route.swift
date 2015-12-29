//
//  Route.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/26/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct Route {
    var name: String
    var id: String
    var stations: [Station]
}

extension Route {
    static let DemoRoutes = [
        Route(name: "Silver Loop", id: "13", stations: []),
        Route(name: "Tower Acres", id: "15", stations: []),
        Route(name: "Simple Loop", id: "01", stations: [
            Station.DemoStations[0],
            Station.DemoStations[1],
            Station.DemoStations[2]
        ])
    ]
}