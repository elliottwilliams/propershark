//
//  JointStationTripViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

struct JointStationTripViewModel: Hashable, CustomStringConvertible {
    let trips: [TripViewModel]
    let station: StationViewModel?
    let nextStation: StationViewModel
    
    var vehicles: [VehicleViewModel] { return trips.map { $0.vehicle } }
    var hashValue: Int { return (station?.hashValue ?? 0) ^ nextStation.hashValue }
    var description: String {
        return "JointStationTripViewModel(trips: \(self.trips), station: \(self.station), nextStation: \(self.nextStation))"
    }
    
    init(trips: [TripViewModel], station: StationViewModel?, nextStation: StationViewModel) {
        self.trips = trips
        self.station = station
        self.nextStation = nextStation
    }
    
    func hasVehicles() -> Bool {
        return self.trips.count > 0
    }
    
    func hasStation() -> Bool {
        return self.station != nil
    }
    
    func displayText() -> String? {
        return station?.name
    }
    
    func subtitleText() -> String? {
        let vehicles = trips.map { $0.vehicle }
        if hasStation() && hasVehicles() {
            return "\(pluralizedVehicles(vehicles)) arrived"
        } else if hasVehicles() {
            return "\(pluralizedVehicles(vehicles)) in transit to \(trips.first!.currentStation().name)"
        } else {
            return nil
        }
    }
    
    func withTrips(trips: [TripViewModel]) -> JointStationTripViewModel {
        return JointStationTripViewModel(trips: trips, station: self.station, nextStation: self.nextStation)
    }
    
    func withStation(station: StationViewModel) -> JointStationTripViewModel {
        return JointStationTripViewModel(trips: self.trips, station: station, nextStation: self.nextStation)
    }
    
    // Oxford comma implicit
    func pluralizedVehicles(vehicles: [VehicleViewModel]) -> String {
        if (vehicles.count == 1) {
            return "#\(vehicles.first!.id)"
        } else if (vehicles.count == 2) {
            return "#\(vehicles[0].id) and #\(vehicles[1].id)"
        } else {
            var ids = vehicles.map { "#" + $0.id }
            ids[ids.count-1] = "and " + ids[ids.count-1]
            return ids.joinWithSeparator(", ")
        }
    }
    
    func routeColor() -> UIColor? {
        return trips.first?.route.color
    }
    
    func hasDifferentVehiclesFrom(instance: JointStationTripViewModel) -> Bool {
        let ours = Set(self.vehicles)
        let theirs = Set(instance.vehicles)
        if ours.exclusiveOr(theirs).isEmpty {
            return false
        } else {
            return true
        }
    }
    
    struct DeltaOfPairLists {
        let needsInsertion: Set<JointStationTripViewModel>
        let needsDeletion: Set<JointStationTripViewModel>
        let needsReloading: Set<JointStationTripViewModel>
    }
    
    // Deduce the changes made to a list of JointStationTripViewModel instances
    static func deltaFromPairList(a: [JointStationTripViewModel], toList b: [JointStationTripViewModel]) -> DeltaOfPairLists? {
        // Get an ordering of stations
        let stations = a.filter { $0.station != nil }
        
        // Return nil if a and b don't contain the same stations in the same sequence. This function is intended to be used on routes.
        let bStations = b.filter({ $0.station != nil })
        if stations.count != bStations.count {
            return nil
        }
        for i in bStations.indices {
            if stations[i] != bStations[i] {
                return nil
            }
        }
        
        let aSet = Set(a)
        let bSet = Set(b)
        let added = bSet.subtract(aSet)
        let removed = aSet.subtract(bSet)
        let same = bSet.intersect(aSet) // intersection from bSet ensures the instances will have the new vehicles
        
        return DeltaOfPairLists(needsInsertion: added, needsDeletion: removed, needsReloading: same)
    }
    
}

func ==(a: JointStationTripViewModel, b: JointStationTripViewModel) -> Bool {
    return a.station == b.station && a.nextStation == b.nextStation
}