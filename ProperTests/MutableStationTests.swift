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

class MutableStationTests: XCTestCase, MutableModelTestSpec {
    typealias Model = MutableStation

    var rawModel = rawModels().station
    var model = decodedModels().station
    let delegate = MutableModelDelegateMock()
    let modifiedStation = Station(stopCode: "BUS100W", name: "~modified", description: nil, position: nil,
                                  routes: nil, vehicles: nil)
    let mock = ConnectionMock()
    var mutable: MutableStation!

    override func setUp() {
        super.setUp()
        self.mutable = MutableStation(from: model, delegate: delegate, connection: mock)
    }

    func testApplyUpdatesProperty() {
        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
        try! mutable.apply(modifiedStation)
        XCTAssertEqual(mutable.name.value, "~modified", "Station name not modified by signal")
    }

    func testProducerApplies() {
        // When producer is subscribed...
        mutable.producer.start()

        // Then a the name should change when an update is published.
        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ")
        mock.publish(to: model.topic, event: .Station(.update(object: .Success(modifiedStation), originator: model.topic)))
        XCTAssertEqual(mutable.name.value, "~modified")
    }

    func testPropertyAccessDoesntStartProducer() {
        mutable.producer = SignalProducer.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }

        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
    }
}

