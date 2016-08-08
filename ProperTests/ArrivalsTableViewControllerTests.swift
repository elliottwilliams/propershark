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
        controller = ArrivalsTableViewController(observing: station, delegate: self, style: .Plain, connection: mock,
                                                 config: .sharedInstance)
        disposable = CompositeDisposable()
    }

    override func tearDown() {
        disposable.dispose()
        super.tearDown()
    }

    func requestView() {
        let _ = controller.view
    }

    func testSubscribeToStation() {
        // When the view is loaded...
        requestView()

        // ...then the topic for its station should be subscribed to.
        XCTAssertTrue(ConnectionMock.subscribed("stations.BUS100W"))
    }

    func testRoutesSignalEmitsOnChanges() {
        // Given
        let payload = ["stop_code": station.stopCode, "associated_objects": ["Shark::Route": ["routes.221B"]]]

        // When the list of routes on a station changes...
        requestView()
        mock.publish(to: station.topic, event: .Station(.update(object: payload, originator: station.topic)))

        // ...expect the routes signal to emit a new set of routes.
        XCTAssertTrue(controller.routes.value.contains { $0.identifier == "221B" })
        XCTAssertEqual(controller.routes.value.count, 1)
    }

    func testRoutesSignalSubscribesToRoutes() {
        // Given
        let payload = ["short_name": "5B", "name": "~modified"]

        // When view loads, route should be subscribed to.
        requestView()
        XCTAssertTrue(ConnectionMock.subscribed("routes.5B"))

        // Thus, when a route update is published (establishing name), route name should change.
        mock.publish(to: "routes.5B", event: .Route(.update(object: payload, originator: "routes.5B")))
        XCTAssertNotNil(controller.routes.value.first)
        if let route = controller.routes.value.first {
            XCTAssertEqual(route.name.value, "~modified")
        }
    }


    func testRouteUnsubscribedWhenLeft() {
        // Given a route subscribed to from when the view was created
        requestView()
        XCTAssertTrue(ConnectionMock.subscribed("routes.5B"))

        // When a route is removed from the station's associatons...
        controller.station.routes.swap(Set())

        // ...it should be unsubscribed from.
        XCTAssertFalse(ConnectionMock.subscribed("routes.5B"))
    }

    func testVehiclesSignalForNewVehicles() {
        // Given
        let vehicles = [
            Vehicle(id: "test1"),
            Vehicle(id: "test2"),
            Vehicle(id: "test3")
        ]
        let modifiedRoute = Route(shortName: "5B", code: nil, name: nil,
                                  description: nil, color: nil, path: nil, stations: nil, vehicles: vehicles,
                                  itinerary: nil)

        // When Route 5B is modified to contain a new list of vehicles...
        requestView()
        XCTAssertNotNil(controller.routes.value.first)
        if let route = controller.routes.value.first {
            route.apply(modifiedRoute)
        }

        // ...then the list of vehicles should be updated
        XCTAssertEqual(controller.vehicles.value.map { $0.name }.sort(), vehicles.map { $0.name }.sort())
    }

    func testVehiclesSignalOnInitialVehicles() {
        // When the view is loaded...
        requestView()

        // ...then there should be no known vehicles.
        XCTAssertEqual(controller.vehicles.value.count, 0)
    }


    // MARK: Delegate Methods
    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath) { }
    func arrivalsTable(receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError) { }
    func mutableModel<M: MutableModel>(model: M, receivedTopicEvent event: TopicEvent) { }
}
