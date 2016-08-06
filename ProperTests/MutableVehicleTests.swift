//
//  MutableVehicleTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Result
@testable import Proper

class MutableVehicleTests: XCTestCase, GenericMutableModelTests {
    typealias Model = MutableVehicle

    var rawModel: AnyObject!
    var model: Model.FromModel!
    let defaultDelegate = DefaultDelegate()
    let modifiedVehicle = Vehicle(name: "1201", code: nil, position: nil, capacity: 9001, onboard: nil,
                                  saturation: nil, lastStation: nil, nextStation: nil, route: nil, scheduleDelta: nil,
                                  heading: nil, speed: nil)
    override func setUp() {
        super.setUp()
        self.rawModel = rawModels().vehicle
        self.model = decodedModels().vehicle
    }

    func testApplyUpdatesProperty() {
        let mutable = createMutable(defaultDelegate)
        XCTAssertEqual(mutable.capacity.value, 60)
        mutable.apply(modifiedVehicle)
        XCTAssertEqual(mutable.capacity.value, 9001)
    }


    func testPropertyAccessDoesntStartProducer() {
        let mutable = createMutable(defaultDelegate)
        mutable.producer = SignalProducer<Vehicle, NoError>.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }
        XCTAssertEqual(mutable.capacity.value, 60)
    }

    func testProducerForwardsModels() {
        let mock = ConnectionMock()
        let mutable = MutableVehicle(from: modifiedVehicle, delegate: defaultDelegate, connection: mock)
        let expectation = expectationWithDescription("Model forwarded")
        mutable.producer.startWithNext { vehicle in
            XCTAssertEqual(vehicle.capacity, self.model.capacity)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.capacity.value, 9001)
        mock.publish(to: model.topic, event: .Vehicle(.update(object: rawModel, originator: model.topic)))

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
