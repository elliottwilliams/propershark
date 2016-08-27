//
//  ThrowingCurryTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
//@testable import func Proper.curry

class ThrowingCurryTests: XCTestCase {

    func curry<A, B>(function: (A) throws -> B)(_ a: A) rethrows -> B {
        return try function(a)
    }

    func curry<A, B, C>(function: (A, B) throws -> C)(_ a: A)(_ b: B) rethrows -> C {
        return try function(a, b)
    }

    func wtf(function: () throws -> Int) rethrows -> Int {
        try function()
    }

    enum Err: ErrorType {
        case Orr
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testThrowing() {

        func a2(x: Int) throws -> Int {
            if x == 0 { throw Err.Orr }
            else { return x+2 }
        }
        func b2(x: Int, _ y: Int) throws -> Int {
            if x+y == 0 { throw Err.Orr }
            else { return x+y+2 }
        }

        let ca2 = curry(a2)
        let cb2 = curry(b2)
    }

    func testNice() {
        func a2(x: Int) -> Int {
            return x+2
        }
        let ca2: Int -> Int = curry(a2)
        ca2(4)
    }

}
