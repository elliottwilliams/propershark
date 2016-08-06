//
//  GenericMutableModelTests.swift
//  Proper
//
//  Created by Elliott Williams on 8/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
@testable import Proper

// MutableModel tests conform to this, which provides shared utilities between MutableModel tests.
protocol GenericMutableModelTests {
    associatedtype Model: MutableModel
    var rawModel: AnyObject! { get set }
    var model: Model.FromModel! { get set }

    func testApplyUpdatesProperty()
    func testProducerForwardsModels()
    func testPropertyAccessDoesntStartProducer()
}

extension GenericMutableModelTests {
    func createMutable(delegate: MutableModelDelegate, connection: ConnectionType = ConnectionMock()) -> Model {
        return Model(from: model, delegate: delegate, connection: connection)
    }
}

internal class DefaultDelegate: MutableModelDelegate {
    func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
    }
    func mutableModel<M : MutableModel>(model: M, receivedTopicEvent event: TopicEvent) {
    }
}


