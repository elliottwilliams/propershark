//
//  RouteViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct RouteViewModel: Hashable, CustomStringConvertible {
    let _route: Route
    let _arrivals: [ArrivalViewModel]
    
    // MARK: Computed properties
    
    var name: String { return _route.name }
    var id: String { return _route.id }
    var color: UIColor { return _route.color }
    var stations: [StationViewModel] { return _route.stations.map { $0.viewModel() } }
    var arrivals: [ArrivalViewModel] { return _arrivals }
    
    var hashValue: Int { return _route.hashValue }
    var description: String {
        return "RouteViewModel(\(self._route))"
    }
    
    init(_ route: Route, arrivals: [ArrivalViewModel]) {
        _route = route
        _arrivals = arrivals
    }
    init(_ route: Route) {
        self.init(route, arrivals: [])
    }
    
    func routeNumber() -> String {
        return _route.id
    }
    
    func displayName() -> String {
        return "\(_route.id) \(_route.name)"
    }
    
    @available(*, deprecated=1.0, message="use stations property")
    func stationsAlongRoute() -> [StationViewModel] {
        return _route.stations.map { $0.viewModel() }
    }
    
    func tripsForRoute() -> [TripViewModel] {
        return _arrivals.map { $0.trip }
    }
    
    func liveStationList() -> [StationViewModel] {
        var stations = self.stations
        let inTransit = _arrivals.filter { !$0.hasArrived }
        
        // For arrivals that have not yet arrived, use station view models with inTransit = true. These will be displayed separately in the table
        inTransit.forEach { arrival in
            if !stations.contains(arrival.station) {
                let i = stations.indexOf(arrival.station.withIsInTransit(false))
                stations[i!] = stations[i!].withoutArrival(arrival)
                stations.insert(arrival.station, atIndex: i!)
            }
        }
        return stations
    }
    
    func withArrivals(arrivals: [ArrivalViewModel]) -> RouteViewModel {
        return RouteViewModel(self._route, arrivals: arrivals)
    }
}

func ==(a: RouteViewModel, b: RouteViewModel) -> Bool {
    return a._route == b._route
}
