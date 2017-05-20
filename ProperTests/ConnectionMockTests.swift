//
//  ConnectionMockTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/4/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

class ConnectionMockTests: XCTestCase {

    let event = TopicEvent.Meta(.unknownLastEvent(["foo"], ["bar": "baz"]))

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func compareEvent(_ args: WampArgs, _ kwargs: WampKwargs) -> Bool {
        let hasArgs = (args as? [String])?.contains("foo") ?? false
        let hasKwargs = (kwargs as? [String: String])?["bar"] == "baz"
        return hasArgs && hasKwargs
    }

    func checkEvent(_ event: TopicEvent) {
        if case .Meta(.unknownLastEvent(let args, let kwargs)) = event {
            XCTAssertTrue(self.compareEvent(args, kwargs), "Unexpected event")
        } else {
            XCTFail("Expected TopicEvent not received")
        }
    }

    func testRPC() {
        let mock = ConnectionMock()
        mock.on("it", send: event)

        let expectation = self.expectation(description: "callback")
        mock.call("it").startWithValues { event in
            self.checkEvent(event)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testUnexpectedRPC() {
        let mock = ConnectionMock()

        mock.call("it").on(event: { event in
            XCTFail("\(type(of: event)) was received even though no RPC call was defined")
        }).start()
    }

    func testPubSub() {
        let mock = ConnectionMock()
        let expectationA = expectation(description: "first callback")
        var fulfilled = false
        let expectationB = expectation(description: "second callback")
        mock.subscribe("it").startWithValues { event in
            self.checkEvent(event)
            if !fulfilled {
                expectationA.fulfill()
                fulfilled = true
            } else {
                expectationB.fulfill()
            }
        }

        // observer should get called twice
        mock.publish(to: "it", event: event)
        mock.publish(to: "it", event: event)
        // but not on another topic
        mock.publish(to: "not_it", event: event)

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testUnsubscribe() {
        let mock = ConnectionMock()
        let disposable = mock.subscribe("it").startWithValues { _ in
            XCTFail("Message received when this producer should have been unsubscribed")
        }
        disposable.dispose()
        mock.publish(to: "it", event: event)
        XCTAssertNil(mock.server.topics["it"], "Not removed from channel storage")
    }

    func testSubscribeCallback() {
        let expectation = self.expectation(description: "subscribed callback")
        let mock = ConnectionMock(onSubscribe: { topic in
            XCTAssertEqual(topic, "it")
            expectation.fulfill()
        })
        mock.subscribe("it")
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testSubscribedQuery() {
        // Given
        let mock = ConnectionMock()

        // When test subscribed to, it should report it.
        let disposable = mock.subscribe("it").start()
        XCTAssertTrue(mock.subscribed("it"))

        // When unsubscribed, it should report correctly, too.
        disposable.dispose()
        XCTAssertFalse(mock.subscribed("it"))
    }

}
