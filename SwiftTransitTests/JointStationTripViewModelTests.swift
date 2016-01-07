//
//  JointStationTripViewModelTests.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 1/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import SwiftTransit


class JointStationTripViewModelTests: XCTestCase {
    
    let trips = TestData.trips.map { $0.viewModel() }
    let station = TestData.stations[0].viewModel()
    
    var testInstance: JointStationTripViewModel!
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHasVehicles() {
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station)
        XCTAssert(testInstance.hasVehicles() == true)
        testInstance = JointStationTripViewModel(trips: [], station: self.station)
        XCTAssert(testInstance.hasVehicles() == false)
    }
    
    func testHasStation() {
        testInstance = JointStationTripViewModel(trips: [], station: self.station)
        XCTAssert(testInstance.hasStation() == true)
        testInstance = JointStationTripViewModel(trips: [], station: nil)
        XCTAssert(testInstance.hasStation() == false)
    }
    
    func testDisplayTextIsStationName() {
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station)
        XCTAssert(testInstance.displayText() == "Hogwarts")
    }
    
    func testSubtitleTextForVehiclesInTransit() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: nil)
        XCTAssertEqual(testInstance.subtitleText(), "#1111 in transit to Hogwarts")
        testInstance = JointStationTripViewModel(trips: self.trips, station: nil)
        XCTAssertEqual(testInstance.subtitleText(), "#1111, #2222, and #3333 in transit to Hogwarts")
    }
    
    func testSubtitleTextForEmptyStation() {
        testInstance = JointStationTripViewModel(trips: [], station: self.station)
        XCTAssertNil(testInstance.subtitleText())
    }
    
    func testSubtitleTextForVehiclesAtStation() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station)
        XCTAssertEqual(testInstance.subtitleText(), "#1111 arrived")
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station)
        XCTAssertEqual(testInstance.subtitleText(), "#1111, #2222, and #3333 arrived")
    }
    
    func testPluralizedVehicles() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station)
        XCTAssertEqual(testInstance.pluralizedVehicles(TestData.vehicles.map { $0.viewModel() }),
            "#1111, #2222, and #3333")
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station)
        let slice = TestData.vehicles.prefix(2)
        XCTAssertEqual(testInstance.pluralizedVehicles(slice.map { $0.viewModel() }),
            "#1111 and #2222")
    }
    
    func testRouteColor() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station)
        XCTAssertEqual(testInstance.routeColor(), self.trips[0].route.color)
        testInstance = JointStationTripViewModel(trips: [], station: self.station)
        XCTAssertNil(testInstance.routeColor())
    }
    
}
