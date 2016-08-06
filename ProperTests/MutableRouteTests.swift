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

class MutableRouteTests: XCTestCase, GenericMutableModelTests {
    typealias Model = MutableRoute

    var rawModel: AnyObject!
    var model: Model.FromModel!
    let defaultDelegate = DefaultDelegate()
    let modifiedRoute = Route(shortName: "19", code: nil, name: "~modified", description: nil, color: nil,
                              path: nil, stations: nil, vehicles: nil, itinerary: nil)
    override func setUp() {
        super.setUp()
        self.rawModel = rawModels().route
        self.model = decodedModels().route
    }

    func testApplyUpdatesProperty() {
        let mutable = createMutable(defaultDelegate)
        XCTAssertEqual(mutable.name.value, "Inner Loop")
        mutable.apply(modifiedRoute)
        XCTAssertEqual(mutable.name.value, "~modified")
    }


    func testPropertyAccessDoesntStartProducer() {
        let mutable = createMutable(defaultDelegate)
        mutable.producer = SignalProducer<Route, NoError>.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }
        XCTAssertEqual(mutable.name.value, "Inner Loop")
    }

    func testProducerForwardsModels() {
        let mock = ConnectionMock()
        let mutable = MutableRoute(from: modifiedRoute, delegate: defaultDelegate, connection: mock)
        let expectation = expectationWithDescription("Model forwarded")
        mutable.producer.startWithNext { route in
            XCTAssertEqual(route.name, self.model.name)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.name.value, "~modified")
        mock.publish(to: model.topic, event: .Route(.update(object: rawModel, originator: model.topic)))

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
