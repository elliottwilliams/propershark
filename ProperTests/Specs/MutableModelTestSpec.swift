//
//  MutableModelTestSpec.swift
//  Proper
//
//  Created by Elliott Williams on 8/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

// MutableModel tests conform to this, which provides shared utilities between MutableModel tests.
protocol MutableModelTestSpec {
    func testApplyUpdatesProperty()
    func testProducerApplies()
    func testPropertyAccessDoesntStartProducer()
}

