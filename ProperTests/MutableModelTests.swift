//
//  MutableModelTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Result
import ReactiveCocoa
@testable import Proper

class MutableModelTests: XCTestCase {

    var route: MutableRoute!
    var mock: ConnectionMock!
    let defaultDelegate = MutableModelDelegateMock()

    var stations: [String]!

    override func setUp() {
        super.setUp()
        mock = ConnectionMock()
        stations = ["BUS403", "BUS922", "BUS162", "BUS161", "BUS897", "BUS375W"]

        let expectation = expectationWithDescription("fixtures")
        Route.fixture("routes.4B").startWithNext { model in
            self.route = try! MutableRoute(from: model, delegate: self.defaultDelegate, connection: self.mock)
            expectation.fulfill()
        }
        self.continueAfterFailure = false
        waitForExpectationsWithTimeout(5.0, handler: nil)
        self.continueAfterFailure = true
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testApplyChangesApplies() {
        // Given
        let modifiedStations = stations.map { Station(stopCode: $0, name: "~modified") }
        let expectation = expectationWithDescription("names applied")
        let nameSignals = route.stations.value.map { $0.name.signal }

        // After emitting `modifiedStations.count` route names, invoke this observer.
        SignalProducer(values: nameSignals).flatMap(.Merge, transform: { signal in signal })
        .collect(count: modifiedStations.count)
        .startWithNext { names in
            expectation.fulfill()
            let should = [String](count: modifiedStations.count, repeatedValue: "~modified")
            XCTAssertEqual(names.flatMap { $0 }, should)
        }

        // When
        XCTAssertNotNil(try? route.attachOrApplyChanges(to: route.stations, from: modifiedStations))

        // Then
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testApplyChangesRemoves() {
        // Given
        var modifiedStations = stations.map { Station(stopCode: $0, name: "~modified", description: nil,
            position: nil, routes: nil, vehicles: nil) }
        modifiedStations.removeFirst()

        // When
        XCTAssertNotNil(try? route.attachOrApplyChanges(to: route.stations, from: modifiedStations))

        // Then
        XCTAssertFalse(route.stations.value.map { $0.identifier }.contains("BUS249") == true)
    }

    func testApplyChangesInserts() {
        // Given
        var modifiedStations = stations.map { Station(stopCode: $0, name: "~modified", description: nil,
            position: nil, routes: nil, vehicles: nil) }
        modifiedStations.append(Station(id: "test123"))

        // When
        XCTAssertNotNil(try? route.attachOrApplyChanges(to: route.stations, from: modifiedStations))

        // Then
        XCTAssertTrue(route.stations.value.map { $0.identifier }.contains("test123") == true)
    }
}
