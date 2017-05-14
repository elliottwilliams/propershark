//
//  TimetableTests.swift
//  Proper
//
//  Created by Elliott Williams on 3/30/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import XCTest
import ReactiveCocoa
import Argo
@testable import Proper

class TimetableTests: XCTestCase {

    var connection: ConnectionMock!
    var scheduler: TestScheduler!
    var disposable: CompositeDisposable!

    var station: MutableStation!

    let startDate = Date(timeIntervalSince1970: 1489686630) // Thu, 16 Mar 2017 17:50:30 GMT
    let endDate = Date(timeIntervalSince1970: 1489690230)   // Thu, 16 Mar 2017 18:50:30 GMT
    
    override func setUp() {
        super.setUp()
        connection = ConnectionMock()
        disposable = CompositeDisposable()
        
        station = try! MutableStation(from: Station(stopCode: "TEST1"), connection: connection)
    }

    override func tearDown() {
        disposable.dispose()
        super.tearDown()
    }

    func testGetArrivalsFromMoreContinuation() {
        // Setup: Form two Timetable responses.
        let responses = [
            response.map({ Array($0[0..<2]) }),
            response.map({ Array($0[2..<3]) })
            ]
        connection.on("timetable.visits_between", send: TopicEvent.Timetable(.arrivals(responses[0])))
        let completed = expectation(description: "got an arrival by calling the continuation")

        // Given a call to `visits`...
        let producer = Timetable.visits(for: station, occurring: .between(startDate, endDate), using: connection,
                                        initialLimit: 2).logEvents(identifier: #function, logger: logSignalEvent)


        var seen = 0
        var calledMore = false
        producer.startWithResult { result in
            guard let result = result.value else {
                XCTFail("Error returned from producer")
                return
            }

            // Each nth arrival should match the nth member of the response array.
            XCTAssertEqual(try! self.response.dematerialize()[seen].makeArrival(using: self.connection),
                result.arrival)

            switch seen {
            case 0:
                break
            case 1:
                // Call the `more` continuation after the second arrival is received.
                self.connection.on("timetable.visits_between", send: TopicEvent.Timetable(.arrivals(responses[1])))
                let time_10ms = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 10)
                dispatch_after(time_10ms, dispatch_get_main_queue()) {
                    calledMore = true
                    result.more()
                }
            case 2:
                // The 3rd arrival should *only* appear after `more` was called.
                if calledMore { completed.fulfill() }
                else          { XCTFail("More than the initial count received") }
            default:
                // Exactly 3 arrivals should be sent.
                XCTFail("received message \(seen), only 0...2 expected")
            }

            seen += 1
        }

        waitForExpectations(timeout: 2, handler: nil)
    }
    

    let response: Decoded<[Proper.Timetable.Response]> = decodeArray(JSON([
        [
            "20170316 13:51:00",
            "20170316 13:51:00",
            "23",
            "to Wabash Landing & Lafayette"
        ],
        [
            "20170316 14:06:00",
            "20170316 14:06:00",
            "23",
            "to Wabash Landing & Lafayette"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "6B",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "3",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "2A",
            "to/from CityBus Center & Schuyler Ave"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "9",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "7",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "1A",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "4A",
            "to CityBus Center"
        ],
        [
            "20170316 14:10:00",
            "20170316 14:10:00",
            "2B",
            "to Union & Underwood"
        ]
    ]))
}
