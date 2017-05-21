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

class CachedConnection<C: ConnectionType>: ConnectionType {
    let connection: C
    let cache = LastEventCache()

    init(_ connection: C) {
        self.connection = connection
    }

    // Returns a producer which will check the cache before calling the underlying connection.
    func call(_ proc: String, with args: WampArgs, kwargs: WampKwargs) -> EventProducer {
        let hit = EventProducer { observer, _ in
            self.cache.lookup(rpc: proc, args).apply(observer.send)
            observer.sendCompleted()
        }
        let miss = connection.call(proc, with: args, kwargs: kwargs)
            .on(value: { [weak self] in self?.cache.store(event: $0, rpc: proc, args: args) })
        return SignalProducer<EventProducer, ProperError>([hit, miss])
            .flatten(.concat).take(first: 1)
    }

    // Returns a producer of topic events that will update the cache, and will trigger a cache void when the connection
    // terminates.
    func subscribe(to topic: String) -> EventProducer {
        return connection.subscribe(to: topic)
            .on(value: { [weak self] in _ = self?.cache.store(event: $0, topic: topic) })
    }
}

extension Connection {
    static let cachedInstance = CachedConnection(Connection.sharedInstance)
}
