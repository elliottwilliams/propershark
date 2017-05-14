//
//  MutableRouteTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Result
@testable import Proper

class MutableRouteTests: XCTestCase, MutableModelTestSpec {
    typealias Model = MutableRoute

    var model: Route!
    var mutable: MutableRoute!

    let modifiedRoute = Route(shortName: "4B", name: "~modified")
    let mock = ConnectionMock()

    override func setUp() {
        super.setUp()

        let expectation = self.expectation(description: "fixtures")
        Route.fixture("routes.4B").startWithNext { model in
            self.model = model
            self.mutable = try! MutableRoute(from: model, connection: self.mock)
            expectation.fulfill()
        }
        self.continueAfterFailure = false
        waitForExpectations(timeout: 5.0, handler: nil)
        self.continueAfterFailure = true
    }

    func testApplyUpdatesProperty() {
        XCTAssertEqual(mutable.name.value, "Purdue West")
        XCTAssertNotNil(try? mutable.apply(modifiedRoute))
        XCTAssertEqual(mutable.name.value, "~modified")
    }


    func testPropertyAccessDoesntStartProducer() {
        mutable.producer = SignalProducer.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }
        XCTAssertEqual(mutable.name.value, "Purdue West")
    }

    func testProducerApplies() {
        // When producer is subscribed...
        mutable.producer.start()

        // Then the name should change when an update is published
        XCTAssertEqual(mutable.name.value, "Purdue West")
        mock.publish(to: model.topic, event: .Route(.update(object: .Success(modifiedRoute), originator: model.topic)))
        XCTAssertEqual(mutable.name.value, "~modified")
    }

    func testMappedItinerary() {
        // Given a set of static stations, an associated mutable station set and an itinerary...
        let stations = [Station(id: "s1"), Station(id: "s2"), Station(id: "s3"), Station(id: "s4")]
        let associatedStations = Set(stations.map { try! MutableStation(from: $0, connection: mock) })
        let itinerary = [stations[0], stations[1], stations[2], stations[0], stations[1], stations[2], stations[0],
                         stations[1], stations[2]]

        // When the associated stations belong to a mutable route...
        mutable.stations.value = associatedStations

        // Then its mappedItinerary function should return the itinerary in the same sequence...
        let mapped = try! mutable.mappedItinerary(itinerary)
        XCTAssertEqual(mapped.map { $0.identifier }, itinerary.map { $0.identifier })
        // ...and each mapped station should be in `associatedStations`.
        mapped.forEach { station in
            XCTAssertFalse(associatedStations.filter({ $0 === station }).isEmpty)
        }

    }

    func testAppliesItinerary() {
        // Given the full starting itinerary...
        XCTAssertNotNil(mutable.itinerary.value)
        if let itinerary = mutable.itinerary.value {
            XCTAssertEqual(itinerary.count, 202)
        }

        // When a changed itinerary is applied...
        let modified = [Station(id: "BUS403"), Station(id: "BUS922"), Station(id: "BUS162")]
        do {
            try mutable.apply(Route(shortName: mutable.shortName, itinerary: modified))
        } catch {
            XCTFail("Could not apply changed itinerary: \(error)")
        }

        // Itinerary property should update
        XCTAssertNotNil(mutable.itinerary.value)
        if let itinerary = mutable.itinerary.value {
            XCTAssertEqual(itinerary.count, 3)
        }
    }

    func testComputesCanonicalRoute() {
        // Given initial an initial computed canonical route
        XCTAssertEqual(mutable.canonical.value?.stations.count, 56)

        // When a changed itinerary is applied...
        let modified = [Station(id: "BUS403"), Station(id: "BUS922"), Station(id: "BUS162")]
        do {
            try mutable.apply(Route(shortName: mutable.shortName, itinerary: modified))
        } catch {
            XCTFail("Could not apply changed itinerary: \(error)")
        }

        // Then the canonical route should recompute
        XCTAssertEqual(mutable.canonical.value?.stations.count, 3)
    }
}
