//
//  ConnectionStubTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/4/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

class ConnectionStubTests: XCTestCase {

    let event = TopicEvent.Meta(.lastEvent(["foo"], ["bar": "baz"]))

    override func setUp() {
        super.setUp()
        // Reset internal state
        ConnectionStub.Channel.channels = [:]
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func compareEvent(args: WampArgs, _ kwargs: WampKwargs) -> Bool {
        let hasArgs = (args as? [String])?.contains("foo") ?? false
        let hasKwargs = (kwargs as? [String: String])?["bar"] == "baz"
        return hasArgs && hasKwargs
    }

    func checkEvent(event: TopicEvent) {
        if case .Meta(.lastEvent(let args, let kwargs)) = event {
            XCTAssertTrue(self.compareEvent(args, kwargs), "Unexpected event")
        } else {
            XCTFail("Expected TopicEvent not received")
        }
    }

    func testRPC() {
        let stub = ConnectionStub()
        stub.on("it", send: event)

        let expectation = expectationWithDescription("callback")
        stub.call("it").startWithNext { event in
            self.checkEvent(event)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testUnexpectedRPC() {
        let stub = ConnectionStub()

        stub.call("it").on(event: { event in
            XCTFail("\(event.dynamicType) was received even though no RPC call was defined")
        }).start()
    }

    func testPubSub() {
        let stub = ConnectionStub()
        let expectationA = expectationWithDescription("first callback")
        var fulfilled = false
        let expectationB = expectationWithDescription("second callback")
        stub.subscribe("it").startWithNext { event in
            self.checkEvent(event)
            if !fulfilled {
                expectationA.fulfill()
                fulfilled = true
            } else {
                expectationB.fulfill()
            }
        }

        // observer should get called twice
        stub.publish(to: "it", event: event)
        stub.publish(to: "it", event: event)
        // but not on another topic
        stub.publish(to: "not_it", event: event)

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testUnsubscribe() {
        let stub = ConnectionStub()
        let disposable = stub.subscribe("it").startWithNext { _ in
            XCTFail("Message received when this producer should have been unsubscribed")
        }
        disposable.dispose()
        stub.publish(to: "it", event: event)
        XCTAssertNil(ConnectionStub.Channel.channels["it"], "Not removed from channel storage")
    }

}
