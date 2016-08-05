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
    var stub: ConnectionStub!
    var controller: ArrivalsTableViewController!

    var disposable: CompositeDisposable!

    override func setUp() {
        super.setUp()
        stub = ConnectionStub()
        station = createMutable(self)(stub)
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
            let routes = routeSets[1]   // routeSets[0] is info before stub.publish
//        disposable += controller.routes.signal.observeNext { routes in
            XCTAssertTrue(routes.contains { $0.identifier == "221B" })
            XCTAssertEqual(routes.count, 1)
            expectation.fulfill()
        }

        // When
        requestView()
        stub.publish(to: station.topic, event: .Station(.update(object: payload, originator: station.topic)))

        // Expect
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testRoutesSignalSubscribesToRoutes() {
        // Given a routesSignal observer that extracts the name signal of route 5B
        let expectation = expectationWithDescription("received route name update")
        disposable += controller.routesSignal().flatMap(.Latest) { (routes: Set<MutableRoute>) -> Signal<String?, NoError> in
            let expectedRoute = routes.filter { $0.identifier == "5B" }.first!
            return expectedRoute.name.signal
        }.observeNext { routeName in
            XCTAssertEqual(routeName, "~modified")
            expectation.fulfill()
        }

        // When route information is published (establishing name), observer should be invoked
        requestView()
        let payload = ["short_name": "5B", "name": "~modified"]
        stub.publish(to: "routes.5B", event: .Route(.update(object: payload, originator: "routes.5B")))

        waitForExpectationsWithTimeout(3, handler: nil)
    }


    // MARK: Delegate Methods
    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath) { }
    func arrivalsTable(receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedTopicEvent event: TopicEvent) { }
}
