//
//  ModelDecodeTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/1/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
import ReactiveCocoa
@testable import Proper

class ModelDecodeTests: XCTestCase {

    var station: AnyObject!
    var route: AnyObject!
    var vehicle: AnyObject!

    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "fixtures")
        combineLatest(
            Station.rawFixture("stations.BUS100W"),
            Route.rawFixture("routes.4B"),
            Vehicle.rawFixture("vehicles.1801")
        ).startWithNext { station, route, vehicle in
            self.station = station
            self.route = route
            self.vehicle = vehicle
            expectation.fulfill()
        }
        self.continueAfterFailure = false
        waitForExpectations(timeout: 5.0, handler: nil)
        self.continueAfterFailure = true
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDecodeStation() {
        let json = JSON(station)
        let decoded = Station.decode(json)
        XCTAssertNotNil(decoded.value, "Decode error: \(decoded.error)")

        guard let station = decoded.value else { return }

        // Flat attributes
        XCTAssertEqual(station.stopCode, "BUS100W")
        XCTAssertEqual(station.name!, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ")
        XCTAssertEqual(station.position!.lat, 40.454631772913)
        XCTAssertEqual(station.position!.long, -86.92457761911)

        // Associations
        XCTAssertNotNil(station.routes)
        if let routes = station.routes {
            XCTAssertEqual(routes.map{ $0.identifier }, ["10"])
        }
    }

    func testDecodeRoute() {
        let json = JSON(route)
        let decoded = Route.decode(json)
        XCTAssertNotNil(decoded.value, "Decode error: \(decoded.error)")

        guard let route = decoded.value else { return }

        // Flat attributes
        XCTAssertEqual(route.code, 1807)
        XCTAssertEqual(route.color, UIColor(hex: "006400"))
        XCTAssertEqual(route.description, "Purdue West")
        XCTAssertEqual(route.shortName, "4B")
        XCTAssertEqual(route.name, "Purdue West")

        // Path should contain multiple points
        XCTAssertNotNil(route.path)
        if let path = route.path {
            XCTAssertEqual(path.first!, Point(lat: 40.420603, long: -86.894876))
            XCTAssertGreaterThan(path.count, 1)
        }

        // Associated stations should include names
        XCTAssertNotNil(route.stations)
        if let stations = route.stations {
            XCTAssertGreaterThan(stations.count, 1)
            let walmart = stations.filter { $0 == Station(id: "BUS403") }.first
            XCTAssertEqual(walmart?.name, "Walmart West Lafayette (at Shelter) - BUS403")
        }

        // Itinerary should be populated
        XCTAssertNotNil(route.itinerary)
        if let itinerary = route.itinerary, let stations = route.stations {
            XCTAssertGreaterThan(itinerary.count, stations.count)
            XCTAssertTrue(itinerary.filter { $0.identifier == "BUS403" }.count > 1,
                          "A station on the route should appear multiple times.")
        }

        // Route should have associated vehicles
        XCTAssertNotNil(route.vehicles)
        if let vehicles = route.vehicles {
            XCTAssertEqual(vehicles.first?.identifier, "1402")
        }
    }

    func testDecodeVehicle() {
        let json = JSON(vehicle)
        let decoded = Vehicle.decode(json)
        XCTAssertNotNil(decoded.value, "Decode error: \(decoded.error)")

        guard let vehicle = decoded.value else { return }

        XCTAssertEqual(vehicle.name, "1801")
        XCTAssertEqual(vehicle.heading, 268)
        XCTAssertEqual(vehicle.capacity, 60)
        XCTAssertEqual(vehicle.saturation, 10)
        XCTAssertEqual(vehicle.speed, 0)
        XCTAssertEqual(vehicle.onboard, 6)

        XCTAssertEqual(vehicle.position, Point(lat: 40.43215, long:-86.8821))
        XCTAssertEqual(vehicle.route.map { $0.identifier }, "1A")
    }

    func testDecodePoint() {
        let lat = 40.454631772913
        let long = -86.92457761911

        let dict = ["latitude": lat, "longitude": long]
        let array = [lat, long]

        XCTAssertEqual(Point.decode(JSON(dict)).value, Point(lat: lat, long: long))
        XCTAssertEqual(Point.decode(JSON(array)).value, Point(lat: lat, long: long))
    }

}
