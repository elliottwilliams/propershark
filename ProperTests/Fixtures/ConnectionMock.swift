//
//  ConnectionMock.swift
//  Proper
//
//  Created by Elliott Williams on 7/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import MDWamp
import ReactiveSwift
import Result
@testable import Proper

class ConnectionMock: ConnectionType {
  var callMap: [String: TopicEvent] = [:]
  var onSubscribe: ((String) -> ())?

  let server = Server()
  class Server {
    typealias SignalType = Signal<TopicEvent, NoError>
    typealias ObserverType = Observer<TopicEvent, NoError>

    class Topic {
      let id: String
      let (signal, observer) = Signal<TopicEvent, NoError>.pipe()
      var subscribers: Int = 0

      init(_ id: String) {
        self.id = id
      }
    }

    var topics: [String: Topic] = [:]

    func leave(_ id: String) {
      if let topic = find(id) {
        topic.subscribers -= 1
        if topic.subscribers < 1 {
          topics[id] = nil
        }
      }
    }

    func find(_ id: String) -> Topic? {
      return topics[id]
    }

    func findOrCreate(_ id: String) -> Topic {
      if let topic = find(id) {
        return topic
      } else {
        let topic = Topic(id)
        topics[id] = topic
        return topic
      }
    }
  }

  init(onSubscribe: ((String) -> ())? = nil) {
    self.onSubscribe = onSubscribe
  }

  func on(_ proc: String, send event: TopicEvent) {
    callMap[proc] = event
  }

  func publish(to id: String, event: TopicEvent) {
    if let topic = server.find(id) {
      topic.observer.send(value: event)
    }
  }

  func call(_ proc: String, with args: WampArgs, kwargs: WampKwargs) -> SignalProducer<TopicEvent, ProperError> {
    return SignalProducer<TopicEvent, ProperError> { observer, _ in
      if let event = self.callMap[proc] {
        observer.send(value: event)
      }
      }.logEvents(identifier: "ConnectionMock.call(\(proc))", logger: logSignalEvent)
  }

  func subscribe(to id: String) -> SignalProducer<TopicEvent, ProperError> {
    let topic = server.findOrCreate(id)
    topic.subscribers += 1
    self.onSubscribe?(id)
    return SignalProducer<TopicEvent, ProperError> { observer, disposable in
      // Upon disposal, reduce the subscriber count on this channel, potentially deleting it.
      disposable += { self.server.leave(id) }

      // Map channel errors to PSErrors...
      disposable += topic.signal.promoteErrors(ProperError.self)
        // ...and forward to this subscriber's observer
        .observe(observer)
      }.logEvents(identifier: "ConnectionMock.subscribe(\(id))", logger: logSignalEvent)
  }

  func subscribed(to topic: String) -> Bool {
    if let subscribers = server.find(topic)?.subscribers {
      return subscribers > 0
    } else {
      return false
    }
  }
}
