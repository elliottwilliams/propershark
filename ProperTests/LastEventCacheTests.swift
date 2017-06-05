//
//  LastEventCacheTests.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
import ReactiveSwift

@testable import Proper

class LastEventCacheTests: XCTestCase {

  var cache: LastEventCache!

  var vehicle: Vehicle!
  var updateEvent: TopicEvent!
  let ID = "vehicles.1801"

  override func setUp() {
    super.setUp()

    let expectation = self.expectation(description: "fixtures")
    Vehicle.fixture(id: ID).startWithResult({ result in
      switch result {
      case .success(let vehicle):
        self.vehicle = vehicle
        self.updateEvent = TopicEvent.vehicle(.update(object: Decoded.success(vehicle), originator: self.ID))
      case .failure(let error):
        XCTFail("\(error)")
      }
      expectation.fulfill()
    })
    continueAfterFailure = false
    waitForExpectations(timeout: 5, handler: nil)
    continueAfterFailure = true

    cache = LastEventCache()
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testCacheStoresUpdateEvent() {
    // When update event is stored
    cache.store(event: updateEvent, from: ID)

    // It should be retrievable by topic ID
    assertEvent(cache.lastEvent(from: ID, sentIn: ID), vehicle: vehicle)
  }

  func testDelayedVoid() {
    // Given a stored event...
    cache.store(event: updateEvent, from: ID)

    // When it is voided...
    cache.expire(topic: ID)

    // It should not be removed until the next run loop iteration.
    assertEvent(cache.lastEvent(from: ID, sentIn: ID), vehicle: vehicle)

    let expectation = self.expectation(description: "delayed operation")
    DispatchQueue.main.async {
      XCTAssertNil(self.cache.lastEvent(from: self.ID, sentIn: self.ID))
      expectation.fulfill()
    }
    waitForExpectations(timeout: 3, handler: nil)
  }

  func testDelayedVoidCancelledByStore() {
    // Given a stored event that is voided...
    cache.store(event: updateEvent, from: ID)
    cache.expire(topic: ID)

    // When a new event is stored on that topic id...
    cache.store(event: updateEvent, from: ID)

    // Then the event should not be removed on deferral...
    let expectation = self.expectation(description: "deferred operation")
    DispatchQueue.main.async {
      self.assertEvent(self.cache.lastEvent(from: self.ID, sentIn: self.ID), vehicle: self.vehicle)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 3, handler: nil)
  }

  fileprivate func assertEvent(_ event: TopicEvent?, vehicle: Vehicle) {
    if let event = event, case TopicEvent.vehicle(.update(let decoded, _)) = event {
      XCTAssertEqual(decoded.value, vehicle)
    } else {
      XCTFail("decode failed")
    }
  }
}
