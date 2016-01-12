//
//  RouteViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct RouteViewModel: Hashable, CustomStringConvertible {
    let _route: Route
    init(_ route: Route) {
        _route = route
    }
    
    var name: String { return _route.name }
    var id: String { return _route.id }
    var color: UIColor { return _route.color }
    
    var hashValue: Int { return _route.hashValue }
    var description: String {
        return "RouteViewModel(\(self._route))"
    }
    
    func routeNumber() -> String {
        return _route.id
    }
    
    func displayName() -> String {
        return "\(_route.id) \(_route.name)"
    }
    
    func stationsAlongRoute() -> [StationViewModel] {
        return _route.stations.map { $0.viewModel() }
    }
    
    func tripsForRoute() -> [TripViewModel] {
        return Trip.DemoTrips.map { $0.viewModel() }
    }
    
    // This could be better done server-side with a SQL JOIN:
    /* SELECT (station_idx, vehicle_id, station_id)
     *      FROM route_stations, trip, station
     *      WHERE trip.current_station_id = station.station_id
     *          AND route_station.route_id = trip.route_id
     *      ORDER BY station_idx;
    */
    func stationsAlongRouteWithTrips(trips: [TripViewModel], stations: [StationViewModel]) -> [JointStationTripViewModel] {
        
        // Pair the sequenced list of stations with any trips whose vehicle is coming to that station
        var pairs: [JointStationTripViewModel] =
            stations.enumerate().map { (i, station) in
                let nextStation = stations[safe: i+1] ?? stations[0]
                return JointStationTripViewModel(trips: trips.filter { $0.currentStation == station }, station: station, nextStation: nextStation)
            }
        
        // Move vehicles who have not arrived at their current station to a nil station entry *before* the next
        for (var i = 0; i < pairs.count; i++) {
            let pair = pairs[i]
            var shouldKeep = [TripViewModel]()
            var shouldMove = [TripViewModel]()
            for trip in pair.trips {
                if trip.isVehicleAtCurrentStation() {
                    shouldKeep.append(trip)
                } else {
                    shouldMove.append(trip)
                }
            }
            pairs[i] = pairs[i].withTrips(shouldKeep)
            
            if (shouldMove.count > 0) {
                let stationless = JointStationTripViewModel(trips: shouldMove, station: nil, nextStation: pair.station!)
                pairs.insert(stationless, atIndex: i)
                i++
            }
        }
        
        return pairs
    }
    
    func stationsAlongRouteWithTrips() -> [JointStationTripViewModel] {
        return stationsAlongRouteWithTrips(self.tripsForRoute(), stations: self.stationsAlongRoute())
    }

}

func ==(a: RouteViewModel, b: RouteViewModel) -> Bool {
    return a._route == b._route
}
