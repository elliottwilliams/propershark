//
//  TestStructures.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 1/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
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