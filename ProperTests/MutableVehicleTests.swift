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
    typealias Model = MutableVehicle

    var rawModel = rawModels().vehicle
    var model = decodedModels().vehicle
    let defaultDelegate = MutableModelDelegateMock()
    let modifiedVehicle = Vehicle(name: "1201", code: nil, position: nil, capacity: 9001, onboard: nil,
                                  saturation: nil, lastStation: nil, nextStation: nil, route: nil, scheduleDelta: nil,
                                  heading: nil, speed: nil)
    let mock = ConnectionMock()
    var mutable: MutableVehicle!

    override func setUp() {
        super.setUp()
        self.mutable = MutableVehicle(from: model, delegate: defaultDelegate, connection: mock)
    }

    func testApplyUpdatesProperty() {
        XCTAssertEqual(mutable.capacity.value, 60)
        mutable.apply(modifiedVehicle)
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
