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
import Argo
@testable import Proper

class MutableVehicleTests: XCTestCase, MutableModelTestSpec {

    var model: Vehicle!
    var mutable: MutableVehicle!

    let modifiedVehicle = Vehicle(name: "1801", capacity: 9001)
    let mock = ConnectionMock()

    override func setUp() {
        super.setUp()

        let expectation = self.expectation(description: "fixtures")
        Vehicle.fixture("vehicles.1801").startWithNext { model in
            self.model = model
            self.mutable = try! MutableVehicle(from: model, connection: self.mock)
            expectation.fulfill()
        }
        self.continueAfterFailure = false
        waitForExpectations(timeout: 5.0, handler: nil)
        self.continueAfterFailure = true
    }

    func testApplyUpdatesProperty() {
        XCTAssertEqual(mutable.capacity.value, 60)
        XCTAssertNotNil(try? mutable.apply(modifiedVehicle))
        XCTAssertEqual(mutable.capacity.value, 9001)
    }


    func testPropertyAccessDoesntStartProducer() {
        mutable.producer = SignalProducer.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }
        XCTAssertEqual(mutable.capacity.value, 60)
    }

    func testProducerApplies() {
        // When producer is subscribed...
        mutable.producer.start()

        // Then the capacity value should change when an update is published.
        XCTAssertEqual(mutable.capacity.value, 60)
        mock.publish(to: model.topic, event: .Vehicle(.update(object: .Success(modifiedVehicle), originator: model.topic)))
        XCTAssertEqual(mutable.capacity.value, 9001)
    }
}
