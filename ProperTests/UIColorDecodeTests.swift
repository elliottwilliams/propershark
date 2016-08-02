//
//  UIColorDecodeTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/2/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
@testable import Proper

class UIColorDecodeTests: XCTestCase {

    let color = UIColor(rgba: (250.0/255, 202.0/255, 222.0/255, 1.0))

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testDecodeHex() {
        let json = JSON.String("facade")
        XCTAssertEqual(UIColor.decode(json).value, self.color)
    }

    func testDecodeArray255() {
        let json = JSON.Array([.Number(250.0), .Number(202.0), .Number(222.0)])
        XCTAssertEqual(UIColor.decode(json).value, self.color)
    }

    func testDecodeArray1() {
        let json = JSON.Array([.Number(250.0/255), .Number(202.0/255), .Number(222.0/255)])
        XCTAssertEqual(UIColor.decode(json).value, self.color)
    }

}
