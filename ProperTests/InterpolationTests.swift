//
//  InterpolationTests.swift
//  ProperTests
//
//  Created by Elliott Williams on 10/4/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

class InterpolationTests: XCTestCase {
  func testBoundaries() {
    let spline = Interpolation.makeUniform(controlPoints: [1, 2, 3, 4], degree: 1)
    XCTAssertEqual(spline(0.0), 1.0)
    XCTAssertEqual(spline(1.0), 4.0)
  }
}
