//
//  Memoize.swift
//  Proper
//
//  Created by Elliott Williams on 7/29/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Curry
@testable import Proper

class Memoize: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMemoize() {
        var escaped = 3
        func fn(x: Int) -> Int {
            return x + escaped
        }

        let memoized = memoize(fn)
        XCTAssertEqual(memoized(1), 4)
        escaped += 1

        // If the inner closure was memoized, we should not get 5 back.
        XCTAssertEqual(memoized(1), 4)
    }

    func testMemoizedCurry() {
        var escaped = 3
        func fn(x: Int, y: Int) -> Int {
            return x + y + escaped
        }

        let curried = memoizedCurry(fn)
        XCTAssertEqual(curried(1)(1), 5)
        escaped += 1
        XCTAssertEqual(curried(1)(1), 5)
        XCTAssertEqual(curried(1)(2), 7)
        XCTAssertEqual(curried(2)(1), 7)
        XCTAssertEqual(curried(1)(1), 5)
    }

}
