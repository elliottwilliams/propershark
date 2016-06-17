//
//  JointStationTripViewModelTests.swift
//  Proper
//
//  Created by Elliott Williams on 1/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper


class JointStationTripViewModelTests: XCTestCase {
    
    let trips = TestData.trips.map { $0.viewModel() }
    let stations = TestData.stations.map { $0.viewModel() }
    
    var station: StationViewModel?
    var nextStation: StationViewModel!
    var pairs: [JointStationTripViewModel] = []
    var testInstance: JointStationTripViewModel!
    
    override func setUp() {
        pairs = [
            JointStationTripViewModel(trips: [trips[0]],            station: nil,           nextStation: stations[0]),
            JointStationTripViewModel(trips: [],                    station: stations[0],   nextStation: stations[1]),
            JointStationTripViewModel(trips: [trips[0]],            station: stations[0],   nextStation: stations[1]),
            JointStationTripViewModel(trips: [trips[0], trips[1]],  station: nil,           nextStation: stations[1]),
            JointStationTripViewModel(trips: [],                    station: stations[1],   nextStation: stations[0]),
            JointStationTripViewModel(trips: [trips[0], trips[1]],  station: stations[1],   nextStation: stations[0])
        ]
        station = stations[0]
        nextStation = stations[1]
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHasVehicles() {
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station, nextStation: self.nextStation)
        XCTAssert(testInstance.hasVehicles() == true)
        testInstance = JointStationTripViewModel(trips: [], station: self.station, nextStation: self.nextStation)
        XCTAssert(testInstance.hasVehicles() == false)
    }
    
    func testHasStation() {
        testInstance = JointStationTripViewModel(trips: [], station: self.station, nextStation: self.nextStation)
        XCTAssert(testInstance.hasStation() == true)
        testInstance = JointStationTripViewModel(trips: [], station: nil, nextStation: self.nextStation)
        XCTAssert(testInstance.hasStation() == false)
    }
    
    func testDisplayTextIsStationName() {
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station, nextStation: self.nextStation)
        XCTAssert(testInstance.displayText() == "Hogwarts")
    }
    
    func testSubtitleTextForVehiclesInTransit() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: nil, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.subtitleText(), "#1111 in transit to Hogwarts")
        testInstance = JointStationTripViewModel(trips: self.trips, station: nil, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.subtitleText(), "#1111, #2222, and #3333 in transit to Hogwarts")
    }
    
    func testSubtitleTextForEmptyStation() {
        testInstance = JointStationTripViewModel(trips: [], station: self.station, nextStation: self.nextStation)
        XCTAssertNil(testInstance.subtitleText())
    }
    
    func testSubtitleTextForVehiclesAtStation() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.subtitleText(), "#1111 arrived")
        testInstance = JointStationTripViewModel(trips: self.trips, station: self.station, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.subtitleText(), "#1111, #2222, and #3333 arrived")
    }
    
    func testPluralizedVehicles() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.pluralizedVehicles(TestData.vehicles.map { $0.viewModel() }),
            "#1111, #2222, and #3333")
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station, nextStation: self.nextStation)
        let slice = TestData.vehicles.prefix(2)
        XCTAssertEqual(testInstance.pluralizedVehicles(slice.map { $0.viewModel() }),
            "#1111 and #2222")
    }
    
    func testRouteColor() {
        testInstance = JointStationTripViewModel(trips: [self.trips[0]], station: self.station, nextStation: self.nextStation)
        XCTAssertEqual(testInstance.routeColor(), self.trips[0].route.color)
        testInstance = JointStationTripViewModel(trips: [], station: self.station, nextStation: self.nextStation)
        XCTAssertNil(testInstance.routeColor())
    }
    
    // MARK: Static methods
    
    func testDeltaFromPairList() {
        let a = [pairs[1], pairs[4]]
        let b = [pairs[0], pairs[1], pairs[4]]
        let result = JointStationTripViewModel.deltaFromPairList(a, toList: b)
        XCTAssertNotNil(result)
        if let res = result {
            XCTAssertEqual(res.needsInsertion, [pairs[0]])
            XCTAssertEqual(res.needsDeletion, [])
            XCTAssertEqual(res.needsReloading, [pairs[1], pairs[4]])
        }
    }
    
    func testDeltaFromPairListOnUnequalStations() {
        let otherStation = Station(name: "Beauxbatons", id: "BUS101", neighborhood: [], location: (1.2, 1.2)).viewModel()
        let otherPairs = pairs.map { $0.withStation(otherStation) }
        
        // Pair lists comprising of two different station sets shouldn't be compared
        XCTAssertNil(JointStationTripViewModel.deltaFromPairList([pairs[0], pairs[1]], toList: [otherPairs[0], otherPairs[1]]))
        // Nor when there is a differing number of stations on each side
        XCTAssertNil(JointStationTripViewModel.deltaFromPairList([pairs[0]], toList: [otherPairs[0], otherPairs[1]]))
        // ...even when both are made up of trips from the same route
        XCTAssertNil(JointStationTripViewModel.deltaFromPairList([pairs[0], pairs[1]], toList: [pairs[2], pairs[1]]))
    }
    
    // pairs with equal station and next station should be considered equal
    func testCompareJointModels() {
        // ensure different station + nextStation pair combinations are not equal
        XCTAssertNotEqual(pairs[0], pairs[1])
        XCTAssertNotEqual(pairs[1], pairs[4])
        XCTAssertNotEqual(pairs[0], pairs[4])
        
        // ensure we're not checking referential equivalence
        XCTAssertEqual(
            JointStationTripViewModel(trips: [trips[0], trips[1]], station: stations[0], nextStation: stations[1]),
            JointStationTripViewModel(trips: [trips[0], trips[1]], station: stations[0], nextStation: stations[1])
        )
        
        // ensure differing vehicles don't affect equality
        XCTAssertEqual(pairs[1], pairs[2])
    }
    
}
