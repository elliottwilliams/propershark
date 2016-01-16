//
//  RouteViewModelTests.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 1/9/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import SwiftTransit

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
            XCTAssert(route.stations.contains(station._station))
        }
    }
    
    func testStationsAlongRouteWithTripsOrdersCorrectly() {
        let joint = testInstance.stationsAlongRouteWithTrips(tripModels, stations: stations).filter { $0.station != nil }
        for i in stations.indices {
            XCTAssert(stations[i] == joint[i].station)
        }
    }
    
    func testLiveStationListOrdersCorrectly() {
        let list = testInstance.liveStationListFromTrips(tripModels).filter { $0.isInTransit == false }
        list.indices.forEach { i in
            XCTAssertEqual(stations[i], list[i])
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
        
        // the first trip model (for Harry) isn't at Hogwarts yet, so he should be in a nil station heading to hogwarts
        XCTAssertNotNil(joint.first)
        if let first = joint.first {
            XCTAssertTrue(first.vehicles.contains(tripModels[0].vehicle))
            XCTAssertNil(first.station)
            XCTAssertEqual(first.nextStation, stations[0])
        }
    }
    
    func testLiveStationListSeparatesDistantVehicles() {
        let list = testInstance.liveStationListFromTrips(tripModels) 
        // harry isn't at hogwarts yet, and hogwarts is the first station, so we should see two hogwarts entries: the first in transit and the second arrives
        XCTAssertGreaterThanOrEqual(list.count, TestData.stations.count)
        if list.count > 1 {
            XCTAssertEqual(list[0], StationViewModel(TestData.stations[0], isInTransit: true))
            XCTAssertEqual(list[1], StationViewModel(TestData.stations[0], isInTransit: false))
        }
    }
    
    func testStationsAlongRouteWithTripsNextStationWraparound() {
        let joint = testInstance.stationsAlongRouteWithTrips(tripModels, stations: stations)
        XCTAssertNotNil(joint.last)
        if let last = joint.last {
            XCTAssertEqual(last.nextStation, stations[0])
        }
    }
}
