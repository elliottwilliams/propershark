//
//  MutableStationTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Result
@testable import Proper

class MutableStationTests: XCTestCase, GenericMutableModelTests {
    typealias Model = MutableStation

    var rawModel: AnyObject!
    var model: Model.FromModel!
    let defaultDelegate = DefaultDelegate()
    let modifiedStation = Station(stopCode: "BUS100W", name: "~modified", description: nil, position: nil,
                                  routes: nil, vehicles: nil)

    override func setUp() {
        super.setUp()
        self.rawModel = rawModels().station
        self.model = decodedModels().station
    }

    func testApplyUpdatesProperty() {
        let mutable = createMutable(defaultDelegate)
        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
        mutable.apply(modifiedStation)
        XCTAssertEqual(mutable.name.value, "~modified", "Station name not modified by signal")
    }

    func testProducerForwardsModels() {
        let mock = ConnectionMock()
        let mutable = MutableStation(from: modifiedStation, delegate: defaultDelegate, connection: mock)
        let expectation = expectationWithDescription("Model forwarded")
        mutable.producer.startWithNext { station in
            XCTAssertEqual(station.name, self.model.name)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.name.value, "~modified")
        mock.publish(to: model.topic, event: .Station(.update(object: rawModel, originator: model.topic)))

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testPropertyAccessDoesntStartProducer() {
        let mutable = createMutable(defaultDelegate)
        mutable.producer = SignalProducer<Station, NoError>.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }

        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
    }
}

