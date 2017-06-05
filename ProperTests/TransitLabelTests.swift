//
//  TransitLabelTests.swift
//  Proper
//
//  Created by Elliott Williams on 1/5/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

class TransitLabelTests: XCTestCase {

  var testInstance: TransitLabel!

  override func setUp() {
    super.setUp()
    testInstance = TransitLabel()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testChangingToAndFromUppercase() {
    testInstance.text = "Hello"
    testInstance.uppercase = true
    XCTAssert(testInstance.text == "HELLO")
    testInstance.uppercase = false
    XCTAssert(testInstance.text == "Hello")
  }

  func testSettingToNilWithUppercase() {
    testInstance.text = "Hello"
    testInstance.uppercase = true
    XCTAssert(testInstance.text == "HELLO")
    testInstance.text = nil
    XCTAssertNil(testInstance.text)
  }
}
