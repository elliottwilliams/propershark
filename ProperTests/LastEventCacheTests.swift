//
//  LastEventCacheTests.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
import ReactiveCocoa

@testable import Proper

class LastEventCacheTests: XCTestCase {

    var cache: LastEventCache!

    var vehicle: Vehicle!
    var updateEvent: TopicEvent!
    let ID = "vehicles.1801"
    
    override func setUp() {
        super.setUp()

        let expectation = expectationWithDescription("fixtures")
        Vehicle.fixture(ID).startWithResult({ result in
            switch result {
            case .Success(let vehicle):
                self.vehicle = vehicle
                self.updateEvent = TopicEvent.Vehicle(.update(object: Decoded.Success(vehicle), originator: self.ID))
            case .Failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        })
        continueAfterFailure = false
        waitForExpectationsWithTimeout(5, handler: nil)
        continueAfterFailure = true

        cache = LastEventCache()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCacheStoresUpdateEvent() {
        // When update event is stored
        cache.store(ID, event: updateEvent)

        // It should be retrievable by topic ID
        assertEvent(cache.lookup(ID, originator: ID), vehicle: vehicle)
    }

    func testCacheStoresMetaEvent() {
        // When meta.last_event rpc is stored...
        //              ( event type               topic id          originator id )
        cache.store(rpc: "meta.last_event", args: [ID, ID], event: updateEvent)

        // It should be retrievable by topic id...
        assertEvent(cache.lookup(ID, originator: ID), vehicle: vehicle)
        // ...and by meta topic id.
        assertEvent(cache.lookup(rpc: "meta.last_event", [ID, ID]), vehicle: vehicle)
    }

    func testDelayedVoid() {
        // Given a stored event...
        cache.store(ID, event: updateEvent)

        // When it is voided...
        cache.void(ID)

        // It should not be removed until the next run loop iteration.
        assertEvent(cache.lookup(ID, originator: ID), vehicle: vehicle)

        let expectation = expectationWithDescription("delayed operation")
        NSOperationQueue.mainQueue().addOperationWithBlock {
            XCTAssertNil(self.cache.lookup(self.ID, originator: self.ID))
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testDelayedVoidCancelledByStore() {
        // Given a stored event that is voided...
        cache.store(ID, event: updateEvent)
        cache.void(ID)

        // When a new event is stored on that topic id...
        cache.store(ID, event: updateEvent)

        // Then the event should not be removed on deferral...
        let expectation = expectationWithDescription("deferred operation")
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.assertEvent(self.cache.lookup(self.ID, originator: self.ID), vehicle: self.vehicle)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    private func assertEvent(event: TopicEvent?, vehicle: Vehicle) {
        if let event = event, case TopicEvent.Vehicle(.update(let decoded, _)) = event {
            XCTAssertEqual(decoded.value, vehicle)
        } else {
            XCTFail("decode failed")
        }
    }
}
