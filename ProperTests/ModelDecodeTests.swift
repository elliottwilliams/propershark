//
//  ModelDecodeTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/1/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
import Colours
@testable import Proper

class ModelDecodeTests: XCTestCase {

    var station: AnyObject!
    var route: AnyObject!
    var vehicle: AnyObject!

    override func setUp() {
        super.setUp()

        let bundle = NSBundle(forClass: self.dynamicType)
        let stationPath = bundle.pathForResource("station", ofType: "json")!
        let stationData = NSData(contentsOfFile: stationPath)
        station = try! NSJSONSerialization.JSONObjectWithData(stationData!, options: [])

        let routePath = bundle.pathForResource("route", ofType: "json")!
        let routeData = NSData(contentsOfFile: routePath)
        route = try! NSJSONSerialization.JSONObjectWithData(routeData!, options: [])

        let vehiclePath = bundle.pathForResource("vehicle", ofType: "json")!
        let vehicleData = NSData(contentsOfFile: vehiclePath)
        vehicle = try! NSJSONSerialization.JSONObjectWithData(vehicleData!, options: [])
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
        XCTAssertEqual(station.stop_code, "BUS100W")
        XCTAssertEqual(station.name!, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ")
        XCTAssertEqual(station.position!.lat, 40.454631772913)
        XCTAssertEqual(station.position!.long, -86.92457761911)

        // Associations
        XCTAssertNotNil(station.routes)
        if let routes = station.routes {
            XCTAssertEqual(routes.map{ $0.identifier }, ["5B"])
        }
        XCTAssertNotNil(station.vehicles)
        if let vehicles = station.vehicles {
            XCTAssertEqual(vehicles.map{ $0.identifier }, ["1706"])
        }
    }

    func testDecodeRoute() {
        let json = JSON(station)
        let decoded = Route.decode(json)
        XCTAssertNotNil(decoded.value, "Decode error: \(decoded.error)")

        guard let route = decoded.value else { return }

        // Flat attributes
        XCTAssertEqual(route.code!, 1824)
        XCTAssertEqual(route.color!, UIColor(hex: "C71585"))
        XCTAssertEqual(route.description!, "Inner Loop")
        XCTAssertEqual(route.shortName, "19")
        XCTAssertEqual(route.name!, "Inner Loop")

        // Path should contain multiple points
        XCTAssertNotNil(route.path)
        if let path = route.path {
            XCTAssertEqual(path.first!, Point(lat: 40.41967, long: -86.923742))
            XCTAssertGreaterThan(path.count, 1)
        }

        // Stations should be defined, including name
        XCTAssertNotNil(route.stations)
        if let stations = route.stations {
            XCTAssertEqual(stations.map { $0.identifier }.first, "BUS249")
            XCTAssertEqual(stations.flatMap { $0.name }.first, "Discovery Parking Lot (at Shelter) - BUS249")
        }

        XCTAssertNotNil(route.vehicles)
        if let vehicles = route.vehicles {
            XCTAssertEqual(vehicles.first?.identifier, "1202")
        }
    }

    func testDecodeVehicle() {
        let json = JSON(vehicle)
        let decoded = Vehicle.decode(json)
        XCTAssertNotNil(decoded.value, "Decode error: \(decoded.error)")

        guard let vehicle = decoded.value else { return }

        XCTAssertEqual(vehicle.name, "1201")
        XCTAssertEqual(vehicle.heading, 180)
        XCTAssertEqual(vehicle.capacity, 60)
        XCTAssertEqual(vehicle.saturation, 6)
        XCTAssertEqual(vehicle.speed, 0)
        XCTAssertEqual(vehicle.onboard, 4)

        XCTAssertEqual(vehicle.position, Point(lat: 40.454631772913, long: -86.92457761911))
        XCTAssertEqual(vehicle.route.map { $0.identifier }, "9")
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
