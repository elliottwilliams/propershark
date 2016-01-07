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
    let color: UIColor
    
    var hashValue: Int { return id.hashValue }
    
    init(name: String, id: String, stations: [Station], color: UIColor) {
        self.name = name
        self.id = id
        self.stations = stations
        self.color = color
    }
    
    @available(*, deprecated=1.0, message="Routes should always have a specified color")
    init(name: String, id: String, stations: [Station]) {
        self.init(name: name, id: id, stations: stations, color: UIColor.redColor())
    }
}

func ==(a: Route, b: Route) -> Bool {
    return a.id == b.id
}

extension Route {
    func viewModel() -> RouteViewModel {
        return RouteViewModel(self)
    }
    
    static let DemoRoutes = [
        Route(name: "Silver Loop", id: "13", stations: [], color: UIColor(red: 204/255, green: 204/255, blue: 205/255, alpha: 1)),
        Route(name: "Tower Acres", id: "15", stations: [], color: UIColor(red: 0, green: 255/255, blue: 0, alpha: 1)),
        Route(name: "Simple Loop", id: "01", stations: [
            Station.DemoStations[0],
            Station.DemoStations[1],
            Station.DemoStations[2],
            Station.DemoStations[3],
            ], color: UIColor(red: 102/255, green: 102/255, blue: 255/255, alpha: 1))
    ]
}