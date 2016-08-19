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

    var rawModel = rawModels().route
    var model = decodedModels().route
    let delegate = MutableModelDelegateMock()
    let modifiedRoute = Route(shortName: "19", name: "~modified")
    let mock = ConnectionMock()
    var mutable: MutableRoute!

    override func setUp() {
        super.setUp()
        self.mutable = MutableRoute(from: model, delegate: delegate, connection: mock)
    }

    func testApplyUpdatesProperty() {
        XCTAssertEqual(mutable.name.value, "Inner Loop")
        try! mutable.apply(modifiedRoute)
        XCTAssertEqual(mutable.name.value, "~modified")
    }


    func testPropertyAccessDoesntStartProducer() {
        mutable.producer = SignalProducer.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }
        XCTAssertEqual(mutable.name.value, "Inner Loop")
    }

    func testProducerApplies() {
        // When producer is subscribed...
        mutable.producer.start()

        // Then the name should change when an update is published
        XCTAssertEqual(mutable.name.value, "Inner Loop")
        mock.publish(to: model.topic, event: .Route(.update(object: .Success(modifiedRoute), originator: model.topic)))
        XCTAssertEqual(mutable.name.value, "~modified")
    }

    func testMappedItinerary() {
        // Given a set of static stations, an associated mutable station set and an itinerary...
        let stations = [Station(id: "s1"), Station(id: "s2"), Station(id: "s3"), Station(id: "s4")]
        let associatedStations = Set(stations.map { MutableStation(from: $0, delegate: delegate, connection: mock) })
        let itinerary = [stations[0], stations[1], stations[2], stations[0], stations[1], stations[2], stations[0],
                         stations[1], stations[2]]

        // When the associated stations belong to a mutable route...
        mutable.stations.value = associatedStations

        // Then its mappedItinerary function should return the itinerary in the same sequence...
        let mapped = try! mutable.mappedItinerary(itinerary)
        XCTAssertEqual(mapped.map { $0.identifier }, itinerary.map { $0.identifier })
        // ...and each mapped stations should be from the `associatedStations` set.
        mapped.forEach { station in
            XCTAssertTrue(associatedStations.contains(station))
        }

    }

    func testAppliesItinerary() {
        // Given the full starting itinerary...
        XCTAssertNotNil(mutable.itinerary.value)
        if let itinerary = mutable.itinerary.value {
            XCTAssertEqual(itinerary.count, 45)
        }

        // When a changed itinerary is applied...
        let modified = [Station(id: "BUS249"), Station(id: "BUS440"), Station(id: "BUS154")]
        try! mutable.apply(Route(shortName: mutable.shortName, itinerary: modified))

        // Itinerary property should update
        XCTAssertNotNil(mutable.itinerary.value)
        if let itinerary = mutable.itinerary.value {
            XCTAssertEqual(itinerary.count, 3)
        }
    }

    func testComputesCanonicalRoute() {
        // Given initial an initial computed canonical route
        XCTAssertEqual(mutable.canonical.value?.stations.count, 17)

        // When a changed itinerary is applied...
        let modified = [Station(id: "BUS249"), Station(id: "BUS440"), Station(id: "BUS154")]
        try! mutable.apply(Route(shortName: mutable.shortName, itinerary: modified))

        // Then the canonical route should recompute
        XCTAssertEqual(mutable.canonical.value?.stations.count, 3)
    }
}
