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

    var station: Station!
    var mutableStation: ((delegate: MutableModelDelegate) -> MutableStation)!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        (self.station, _, _) = decodedModels()
        self.mutableStation = curry(MutableStation.init)(self.station)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLazyPropertyBindsToSignal() {
        let mutable = mutableStation(delegate: defaultDelegate)
        let modifiedStation = Station(stopCode: station.stopCode, name: "~modified", description: nil, position: nil,
                                      routes: nil, vehicles: nil)

        let expectation = expectationWithDescription("Producer is started and emits a station")
        mutable.producer = SignalProducer<Station, NoError>.init { observer, disposable in
            observer.sendNext(modifiedStation)
            XCTAssertEqual(mutable.name.value, "~modified", "Station name not modified by signal")
            expectation.fulfill()
            disposable.dispose()
        }

        XCTAssertEqual(mutable.name.value, "Beau Jardin Apts on Yeager (@ Shelter) - BUS100W ",
                       "Station name does not have expected initial value")
        mutable.producer.start()

        waitForExpectationsWithTimeout(5, handler: nil)
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