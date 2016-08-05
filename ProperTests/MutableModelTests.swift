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

// MutableModel tests conform to this, which provides shared utilities between MutableModel tests.
protocol MutableModelTests {
    associatedtype Model: MutableModel
    var rawModel: AnyObject! { get set }
    var model: Model.FromModel! { get set }

    func testApplyUpdatesProperty()
    func testProducerForwardsModels()
    func testPropertyAccessDoesntStartProducer()
}
extension MutableModelTests {
    func createMutable(delegate: MutableModelDelegate) -> Model {
        return Model(from: model, delegate: delegate)
    }
}

class MutableStationTests: XCTestCase, MutableModelTests {
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
        let mutable = MutableStation(from: modifiedStation, delegate: defaultDelegate)
        let stub = ConnectionStub()
        let expectation = expectationWithDescription("Model forwarded")
        mutable.connection = stub
        mutable.producer.startWithNext { station in
            XCTAssertEqual(station.name, self.model.name)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.name.value, "~modified")
        stub.publish(to: model.topic, event: .Station(.update(object: rawModel, originator: model.topic)))

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

class MutableRouteTests: XCTestCase, MutableModelTests {
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
        let mutable = MutableRoute(from: modifiedRoute, delegate: defaultDelegate)
        let stub = ConnectionStub()
        let expectation = expectationWithDescription("Model forwarded")
        mutable.connection = stub
        mutable.producer.startWithNext { route in
            XCTAssertEqual(route.name, self.model.name)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.name.value, "~modified")
        stub.publish(to: model.topic, event: .Route(.update(object: rawModel, originator: model.topic)))

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}

class MutableVehicleTests: XCTestCase, MutableModelTests {
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
        let mutable = MutableVehicle(from: modifiedVehicle, delegate: defaultDelegate)
        let stub = ConnectionStub()
        let expectation = expectationWithDescription("Model forwarded")
        mutable.connection = stub
        mutable.producer.startWithNext { vehicle in
            XCTAssertEqual(vehicle.capacity, self.model.capacity)
            expectation.fulfill()
        }

        XCTAssertEqual(mutable.capacity.value, 9001)
        stub.publish(to: model.topic, event: .Vehicle(.update(object: rawModel, originator: model.topic)))

        waitForExpectationsWithTimeout(3, handler: nil)
    }
}

internal class DefaultDelegate: MutableModelDelegate {
    func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
    }
    func mutableModel<M : MutableModel>(model: M, receivedTopicEvent event: TopicEvent) {
    }
}


