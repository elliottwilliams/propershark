//
//  SwiftTransitTests.swift
//  SwiftTransitTests
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import XCTest
@testable import SwiftTransit

struct TestData {
    static let vehicles = [
        Vehicle(name: "Harry", id: "1111", location: (10.0, 10), capacity: 0.5),
        Vehicle(name: "Ron", id: "2222", location: (10.0005, 10), capacity: 0.4),
        Vehicle(name: "Hermione", id: "3333", location: (10.001, 10), capacity: 0.3),
    ]
    static let stations = [
        Station(name: "Hogwarts", id: "BUS001", neighborhood: [], location: (10.0005, 10)),
        Station(name: "Hogsmeade", id: "BUS002", neighborhood: [], location: (10.0012, 10))
    ]
    static var route: Route {
        return Route(name: "Hogwarts Express", id: "99", stations: self.stations)
    }
    static var trips: [Trip] {
        return [
            Trip(vehicle: vehicles[0], route: route, currentStationIdx: 0),
            Trip(vehicle: vehicles[1], route: route, currentStationIdx: 0),
            Trip(vehicle: vehicles[2], route: route, currentStationIdx: 1)
        ]
    }
}

class RouteViewModelTests: XCTestCase {
    var stations = TestData.stations.map { $0.viewModel() }
    let route = TestData.route
    let trips = TestData.trips
    
    var tripModels: [TripViewModel]!
    var testInstance: RouteViewModel!
    
    override func setUp() {
        testInstance = RouteViewModel(route)
        tripModels = trips.map { $0.viewModel() }
    }
    
    func testRouteNumber() {
        XCTAssert(testInstance.routeNumber() == "99")
    }
    
    func testDisplayName() {
        XCTAssert(testInstance.displayName() == "99 Hogwarts Express")
    }
    
    func testStationsAlongRouteReturnsStationViewModelsBelongingToRoute() {
        let stations = testInstance.stationsAlongRoute()
        stations.forEach { station in
            XCTAssert(station.isMemberOfClass(StationViewModel))
            XCTAssert(route.stations.contains(station._station))
        }
    }
    
    func testStationsAlongRouteWithTripsOrdersCorrectly() {
        let joint = testInstance.stationsAlongRouteWithTrips(tripModels, stations: stations).filter { $0.station != nil }
        for i in stations.indices {
            XCTAssert(stations[i] == joint[i].station)
        }
    }
    
    func testStationsAlongRouteWithTripsPairsArrivedVehicles() {
        let joint = testInstance.stationsAlongRouteWithTrips(tripModels, stations: stations)
        let atHogwarts = joint.filter { $0.station == stations[0] }
        XCTAssert(atHogwarts.count == 1)
        
        let firstAtHogwarts = atHogwarts.first
        XCTAssertNotNil(firstAtHogwarts)
        if firstAtHogwarts != nil {
            XCTAssert(firstAtHogwarts!.trips.contains(tripModels[1])) // ron should be at hogwarts
        }
        
        let atHogsmeade = joint.filter { $0.station == stations[1] }
        let firstAtHogsmeade = atHogsmeade.first
        XCTAssert(atHogsmeade.count == 1)
        XCTAssertNotNil(firstAtHogsmeade)
        if firstAtHogsmeade != nil {
            XCTAssert(firstAtHogsmeade!.trips.contains(tripModels[2])) // hermione should be at hogsmeade
        }
    }
    
    func testStationsAlongRouteWithTripsSeparatesDistantVehicles() {
        let joint = testInstance.stationsAlongRouteWithTrips(tripModels, stations: stations)
        let firstTrip = joint.first?.trips.first
        
        XCTAssertNotNil(firstTrip)
        if firstTrip != nil {
            // harry should be traveling to hogwarts but not at hogwarts
            XCTAssert(firstTrip == tripModels[0])
            XCTAssertNil(joint.first!.station)
            // harry's current location should be hogwarts, indicating that the vehicle belongs to the hogwarts station
            XCTAssert(firstTrip!.currentStation == stations[0])
        }
    }
}

class TripTests: XCTestCase {
    let route = Route(name: "Chartreuse Loop", id: "99", stations: TestData.stations)
    
    var testInstance: Trip!
    
    func testCurrentStationInitializesToFirstStation() {
        testInstance = Trip(vehicle: TestData.vehicles.first!, route: route)
        XCTAssert(testInstance.currentStation == 0)
    }
    
    func testWithNextStationSelected() {
        testInstance = Trip(vehicle: TestData.vehicles.first!, route: route)
        testInstance = testInstance.withNextStationSelected()
        XCTAssert(testInstance.currentStation == 1)
    }
    
    func testWithNextStationSelectedRollover() {
        testInstance = Trip(vehicle: TestData.vehicles.first!, route: route)
        for _ in 0..<route.stations.count {
            testInstance = testInstance.withNextStationSelected()
        }
        XCTAssert(testInstance.currentStation == 0)
    }
    
    func testIsVehicleAtCurrentStationWithNoDistance() {
        let loc = route.stations.first!.location
        let vehicle = Vehicle(name: "Here", id: "1111", location: loc, capacity: 0.0)
        testInstance = Trip(vehicle: vehicle, route: route)
        XCTAssert(testInstance.isVehicleAtCurrentStation() == true)
    }
    
    func testIsVehicleAtCurrentStationWithApprox30mDistance() {
        var loc = route.stations.first!.location
        loc.latitude += 0.00025
        let vehicle = Vehicle(name: "Here", id: "1111", location: loc, capacity: 0.0)
        testInstance = Trip(vehicle: vehicle, route: route)
        XCTAssert(testInstance.isVehicleAtCurrentStation() == true)
    }
    
    func testIsVehicleAtCurrentStationWithGT30mDistance() {
        var loc = route.stations.first!.location
        loc.latitude += 0.00035
        let vehicle = Vehicle(name: "Away", id: "1111", location: loc, capacity: 0.0)
        testInstance = Trip(vehicle: vehicle, route: route)
        XCTAssert(testInstance.isVehicleAtCurrentStation() == false)
    }
}