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
}
