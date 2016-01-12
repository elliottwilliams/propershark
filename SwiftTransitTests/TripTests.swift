//
//  TripTests.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 1/9/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import SwiftTransit

class TripTests: XCTestCase {
    let route = Route(name: "Chartreuse Loop", id: "99", stations: TestData.stations, color: UIColor.chartreuseColor())
    
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
