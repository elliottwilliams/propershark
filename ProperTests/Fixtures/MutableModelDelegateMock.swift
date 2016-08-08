//
//  MutableModelDelegateMock.swift
//  Proper
//
//  Created by Elliott Williams on 8/8/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
@testable import Proper

class MutableModelDelegateMock: MutableModelDelegate {

    let (onReceivedError, _errorObserver) = Signal<PSError, NoError>.pipe()
    let (onReceivedTopicEvent, _topicEventObserver) = Signal<TopicEvent, NoError>.pipe()

    func mutableModel<M : MutableModel>(model: M, receivedError error: PSError) {
        _errorObserver.sendNext(error)
    }
    func mutableModel<M : MutableModel>(model: M, receivedTopicEvent event: TopicEvent) {
        _topicEventObserver.sendNext(event)
    }
}
