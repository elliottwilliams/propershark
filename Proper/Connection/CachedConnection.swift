//
//  CachedConnection.swift
//  Proper
//
//  Created by Elliott Williams on 11/26/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Runes

class CachedConnection<C: ConnectionType>: ConnectionType {
    let connection: C
    let cache = LastEventCache()

    init(_ connection: C) {
        self.connection = connection
    }

    // Returns a producer which will check the cache before calling the underlying connection.
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> EventProducer {
        let hit = EventProducer { observer, _ in
            self.cache.lookup(rpc: procedure, args).apply(observer.sendNext)
            observer.sendCompleted()
        }
        let miss = connection.call(procedure, args: args, kwargs: kwargs)
            .on(next: { [weak self] in self?.cache.store(rpc: procedure, args: args, event: $0) })
        return SignalProducer<EventProducer, ProperError>(values: [hit, miss])
            .flatten(.Concat).take(1)
    }

    // Returns a producer of topic events that will update the cache, and will trigger a cache void when the connection
    // terminates.
    func subscribe(topic: String) -> EventProducer {
        return connection.subscribe(topic)
            .on(next: { [weak self] in self?.cache.store(topic, event: $0) },
                terminated: { [weak self] in self?.cache.void(topic) })
    }
}

extension Connection {
    static let cachedInstance = CachedConnection(Connection.sharedInstance)
}
