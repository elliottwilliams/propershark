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
        inTransit.forEach { arrival in
            if !stations.contains(arrival.station) {
                let i = stations.indexOf(arrival.station.withIsInTransit(false))
                stations[i!] = stations[i!].withoutArrival(arrival)
                stations.insert(arrival.station, atIndex: i!)
            }
        }
        return stations
    }
    
    // This could be better done server-side with a SQL JOIN:
    /* SELECT (station_idx, vehicle_id, station_id)
     *      FROM route_stations, trip, station
     *      WHERE trip.current_station_id = station.station_id
     *          AND route_station.route_id = trip.route_id
     *      ORDER BY station_idx;
    */
    @available(*, deprecated=1.0, message="Use a route's live station list, instead")
    func stationsAlongRouteWithTrips(trips: [TripViewModel], stations: [StationViewModel]) -> [JointStationTripViewModel] {
        
        // Pair the sequenced list of stations with any trips whose vehicle is coming to that station
        var pairs: [JointStationTripViewModel] =
            stations.enumerate().map { (i, station) in
                let nextStation = stations[safe: i+1] ?? stations[0]
                return JointStationTripViewModel(trips: trips.filter { $0.currentStation() == station }, station: station, nextStation: nextStation)
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
    
    @available(*, deprecated=1.0, message="Use a route's live station list, instead")
    func stationsAlongRouteWithTrips() -> [JointStationTripViewModel] {
        let trips = Trip.DemoTrips.filter { $0.route == self._route }.map { $0.viewModel() }
        return stationsAlongRouteWithTrips(trips, stations: self.stationsAlongRoute())
    }

    func withArrivals(arrivals: [ArrivalViewModel]) -> RouteViewModel {
        return RouteViewModel(self._route, arrivals: arrivals)
    }
}

func ==(a: RouteViewModel, b: RouteViewModel) -> Bool {
    return a._route == b._route
}
