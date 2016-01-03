//
//  Route.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/26/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct Route: Hashable {
    let name: String
    let id: String
    let stations: [Station]
    
    var hashValue: Int { return id.hashValue }
}

func ==(a: Route, b: Route) -> Bool {
    return a.id == b.id
}

extension Route {
    func viewModel() -> RouteViewModel {
        return RouteViewModel(self)
    }
    
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