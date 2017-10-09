//
//  CachedConnection.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Runes

protocol CachedConnectionProtocol: class {
  var lastEventCache: LastEventCache { get }
}

extension CachedConnectionProtocol {
  func updatingCache(withEventsFrom producer: SignalProducer<TopicEvent, ProperError>, for topic: String) ->
    SignalProducer<TopicEvent, ProperError>
  {
    return producer.on(terminated: { [weak self] in self?.lastEventCache.expire(topic: topic) },
                       value: { [weak self] in _ = self?.lastEventCache.store(event: $0, from: topic) })
  }

  func cacheLookup(_ proc: String, _ args: WampArgs, _ kwargs: WampKwargs) -> EventProducer {
    return EventProducer { observer, _ in
      if proc == "meta.last_event", let topic = args[safe: 0] as? String, let originator = args[safe: 1] as? String {
        self.lastEventCache.lastEvent(from: originator, sentIn: topic).apply(observer.send)
      }
      observer.sendCompleted()
      }.logEvents(identifier: "\(String(describing: Self.self)).cacheLookup(proc: \(proc))",
        events: Set([.value]), logger: logSignalEvent)
  }
}

@available(deprecated, message: "Connection implementations should conform to CachedConnectionProtocol")
class CachedConnection<C: ConnectionType>: ConnectionType, CachedConnectionProtocol {
  let inner: C
  let lastEventCache = LastEventCache()

  init(_ connection: C) {
    self.inner = connection
  }

  // Returns a producer which will check the cache before calling the underlying connection.
  func call(_ proc: String, with args: WampArgs, kwargs: WampKwargs) -> EventProducer {
    let hit = cacheLookup(proc, args, kwargs)
    let miss = inner.call(proc, with: args, kwargs: kwargs)
    return SignalProducer<EventProducer, ProperError>([hit, miss])
      .flatten(.concat).take(first: 1)
  }

  // Returns a producer of topic events that will update the cache, and will trigger a cache void when the connection
  // terminates.
  func subscribe(to topic: String) -> EventProducer {
    return updatingCache(withEventsFrom: inner.subscribe(to: topic), for: topic)
  }
}
