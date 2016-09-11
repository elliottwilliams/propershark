//
//  CanonicalRouteTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

class CanonicalRouteTests: XCTestCase {

    let stations = [
        Station(stopCode: "s0"), Station(stopCode: "s1"), Station(stopCode: "s2"), Station(stopCode: "s3"),
        Station(stopCode: "s4"), Station(stopCode: "s5"), Station(stopCode: "s6"), Station(stopCode: "s7"),
    ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRouteWithoutConditionals() {
        // Given an itinerary of 3 stops without any conditional stops
        let itinerary = [stations[0], stations[1], stations[2], stations[0], stations[1], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then stations should be a set of 3 constant stops
        XCTAssertEqual(route.stations, [.constant(stations[0]), .constant(stations[1]), .constant(stations[2])])
    }

    func testRouteWithInnerConditional() {
        // Given an itinerary with an conditional stop in the middle of one of the loops
        let itinerary = [stations[0], stations[1], stations[2],
                         stations[0], stations[1], stations[3], stations[2],
                         stations[0], stations[1], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then stations should have the conditional stop positioned in between the other constants
        XCTAssertEqual(route.stations, [.constant(stations[0]), .constant(stations[1]),
            .conditional(stations[3]), .constant(stations[2])])
    }

    func testRouteWithInitialConditional() {
        // Given an itinerary which stops at conditional stops first
        let itinerary = [stations[3], stations[4], stations[0], stations[1], stations[2],
                         stations[0], stations[1], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then stations should have the conditional stops, followed by the constant loop
        XCTAssertEqual(route.stations, [.conditional(stations[3]), .conditional(stations[4]),
            .constant(stations[0]), .constant(stations[1]), .constant(stations[2])])
    }

    func testRouteWithEndConditional() {
        // Given an itinerary which makes conditional stops at the end of one of the loops
        let itinerary = [stations[0], stations[1], stations[2],
                         stations[0], stations[1], stations[2], stations[3], stations[4],
                         stations[0], stations[1], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then stations should have the conditional stops at the end of the constant loop
        XCTAssertEqual(route.stations, [.constant(stations[0]), .constant(stations[1]), .constant(stations[2]),
            .conditional(stations[3]), .conditional(stations[4])])
    }

    func testRouteWithMultipleConditionals() {
        // Given an itinerary with different conditionals in different iterations of the main loop
        let itinerary = [stations[3], stations[0], stations[1], stations[2],
                         stations[0], stations[1], stations[4], stations[2],
                         stations[3], stations[0], stations[1], stations[2],
                         stations[5], stations[0], stations[1], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then stations should include all conditionals merged together. Two conditionals appearing in the same "place"
        // along the route should be ordered by the order in which they appear in the itinerary.
        XCTAssertEqual(route.stations, [.conditional(stations[3]), .constant(stations[0]), .constant(stations[1]),
            .conditional(stations[4]), .constant(stations[2]), .conditional(stations[5])])
    }

    func testRouteWithWeirdPattern() {
        // Given an itinerary that stops at the same stop in different places along a constant loop
        let itinerary = [stations[3], stations[0], stations[1], stations[2],
                         stations[0], stations[3], stations[1], stations[2],
                         stations[0], stations[1], stations[3], stations[2]]

        // When canonical route is computed
        let route = CanonicalRoute(from: itinerary)

        // Then all stations should be marked conditional.
        XCTAssertEqual(route.stations, [.conditional(stations[3]), .conditional(stations[0]), .conditional(stations[1]),
            .conditional(stations[2])])
    }
}
