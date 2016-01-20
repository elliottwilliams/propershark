//
//  StationViewModel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

struct StationViewModel: Hashable, CustomStringConvertible {
    
    // MARK: Properties
    let isInTransit: Bool
    let hasVehicles: Bool
    let _station: Station
    let _arrivals: [ArrivalViewModel]
    
    // MARK: Computed properties
    var name: String { return _station.name }
    var id: String { return _station.id }
    var neighborhood: [String]? { return _station.neighborhood }
    var location: (latitude: Double, longitude: Double) { return _station.location }
    var hashValue: Int { return _station.hashValue ^ Int(isInTransit) }
    var description: String {
        if isInTransit {
            return "StationViewModel(in transit, \(self._station))"
        } else {
            return "StationViewModel(\(self._station))"
        }
    }
    
    init(_ station: Station, isInTransit: Bool = false, arrivals: [ArrivalViewModel]? = nil) {
        if let arrivals = arrivals {
            _arrivals = arrivals
        } else {
            _arrivals = Arrival.demoArrivals().filter { $0.station == station }.map { $0.viewModel() }
        }
        _station = station
        self.isInTransit = isInTransit
        self.hasVehicles = _arrivals.count > 0
    }
    
    func arrivalsAtStation() -> [ArrivalViewModel] {
        return _arrivals
    }
    
    func vehiclesAtStation() -> [VehicleViewModel] {
        return _arrivals.map { $0.vehicle() }
    }
    
    @available(*, deprecated=1.0, message="use arrivalsAtStation()")
    func tripsCurrentlyAtStation() -> [TripViewModel] {
        let trips = Trip.DemoTrips.filter { $0.viewModel().currentStation() == self }
        return trips.map { $0.viewModel() }
    }
    
    func mapAnnotation() -> StationMapAnnotation {
        return StationMapAnnotation(loc: self.location)
    }
    
    func displayText() -> String? {
        return self.name
    }
    
    func subtitleText() -> String? {
        let vehicles = self.arrivalsAtStation().map { $0.vehicle() }
        if !vehicles.isEmpty {
            if isInTransit {
                return "\(Vehicle.pluralize(vehicles)) in transit to \(name)"
            } else {
                return "\(Vehicle.pluralize(vehicles)) arrived"
            }
        } else {
            return nil
        }
    }
    
    struct Changeset {
        let inserted: Set<StationViewModel>
        let deleted: Set<StationViewModel>
        let persisted: Set<StationViewModel>
    }
    
    // MARK: Static functions
    static func changesFrom(a: [StationViewModel], to b: [StationViewModel]) -> Changeset {
        let p = Set(a)
        let q = Set(b)
        return Changeset(inserted: q.subtract(p), deleted: p.subtract(q), persisted: p.intersect(q))
    }
    
    // MARK: State transitions
    
    func withIsInTransit(val: Bool) -> StationViewModel {
        return StationViewModel(_station, isInTransit: val)
    }
    
    func withArrivals(arrivals: [ArrivalViewModel]) -> StationViewModel {
        return StationViewModel(_station, isInTransit: self.isInTransit, arrivals: arrivals)
    }
    
    func withoutArrival(arrival: ArrivalViewModel) -> StationViewModel {
        let arrivals = _arrivals.filter { $0 != arrival }
        return StationViewModel(_station, isInTransit: self.isInTransit, arrivals: arrivals)
    }
}

func ==(a: StationViewModel, b: StationViewModel) -> Bool {
    return a._station == b._station && a.isInTransit == b.isInTransit
}

class StationMapAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(loc: (Double, Double)) {
        self.coordinate = CLLocationCoordinate2DMake(loc.0, loc.1)
    }
}