//
//  ArrivalsTableViewControllerTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Result
@testable import Proper

class ArrivalsTableViewControllerTests: XCTestCase, ArrivalsTableViewDelegate, MutableModelDelegate {

    let createMutable = mutableModels().station
    var station: MutableStation!
    var mock: ConnectionMock!
    var controller: ArrivalsTableViewController!

    var disposable: CompositeDisposable!

    override func setUp() {
        super.setUp()
        mock = ConnectionMock()
        station = createMutable(self)(mock)
        controller = ArrivalsTableViewController(observing: station, delegate: self, style: .Plain)
        disposable = CompositeDisposable()
    }

    override func tearDown() {
        disposable.dispose()
        super.tearDown()
    }

    func requestView() {
        let _ = controller.view
    }

    /// When controller loads, a list of routes should be emitted.
    func testRoutesOnLoad() {
        // Given
        let expectation = expectationWithDescription("routes on load")
        disposable += controller.routes.signal.observeNext { routes in
            XCTAssertEqual(routes.count, self.station.routes.value?.count)
            expectation.fulfill()
        }

        // When
        requestView()

        // Expect
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testRoutesSignalEmitsOnChanges() {
        // Given
        let expectation = expectationWithDescription("routes on station update")
        let payload = ["stop_code": station.stopCode, "associated_objects": ["Shark::Route": ["routes.221B"]]]
        disposable += controller.routes.signal.collect(count: 2).observeNext { routeSets in
            let routes = routeSets[1]   // routeSets[0] is info before mock.publish
//        disposable += controller.routes.signal.observeNext { routes in
            XCTAssertTrue(routes.contains { $0.identifier == "221B" })
            XCTAssertEqual(routes.count, 1)
            expectation.fulfill()
        }

        // When
        requestView()
        mock.publish(to: station.topic, event: .Station(.update(object: payload, originator: station.topic)))

        // Expect
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testRoutesSignalSubscribesToRoutes() {
        // Given
        let firstPayload = ["short_name": "5B", "name": "initial name"]
        let secondPayload = ["short_name": "5B", "name": "~modified"]

        // When route information is published (establishing name), route should be subscribed to and name should
        // change.
        requestView()
        XCTAssertNil(controller.routes.value.first!.name.value)
        XCTAssertTrue(ConnectionMock.subscribed("routes.5B"))

        mock.publish(to: "routes.5B", event: .Route(.update(object: firstPayload, originator: "routes.5B")))
        XCTAssertEqual(controller.routes.value.first!.name.value, "initial name")

        mock.publish(to: "routes.5B", event: .Route(.update(object: secondPayload, originator: "routes.5B")))
        XCTAssertEqual(controller.routes.value.first!.name.value, "~modified")
    }


    // MARK: Delegate Methods
    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath) { }
    func arrivalsTable(receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedTopicEvent event: TopicEvent) { }
}
