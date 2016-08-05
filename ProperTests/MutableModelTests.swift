//
//  MutableModelTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Curry
import Result
@testable import Proper

class MutableModelTests: XCTestCase {

    let (rawStation, rawRoute, rawVehicle) = rawModels()
    let (station, route, vehicle) = decodedModels()
    let (mutableStation, mutableRoute, mutableVehicle) = mutableModels()
    let modifiedStation = Station(stopCode: "BUS100W", name: "~modified", description: nil, position: nil,
                                  routes: nil, vehicles: nil)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Connection.sharedInstance.wamp.value = nil
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testApplyUpdatesProperty() {
        let mutable = mutableStation(delegate: defaultDelegate)

        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
        mutable.apply(modifiedStation)

        XCTAssertEqual(mutable.name.value, "~modified", "Station name not modified by signal")
    }

    func testPropertyAccessDoesntStartProducer() {
        let mutable = mutableStation(delegate: defaultDelegate)
        mutable.producer = SignalProducer<Station, NoError>.init { observer, disposable in
            XCTFail("Signal producer started due to property access")
        }

        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
    }

    let defaultDelegate = DefaultDelegate()
    class DefaultDelegate: MutableModelDelegate {
        func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
        }
        func mutableModel<M : MutableModel>(model: M, receivedTopicEvent event: TopicEvent) {
        }
    }

}


