//
//  LastEventCache.swift
//  Proper
//
//  Created by Elliott Williams on 9/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

/// `NSCache`-backed storage for looking up responses to `meta.last_event`.
class LastEventCache: NSObject {
    let cache = NSCache<NSString, Box<TopicEvent>>()

    /// Create a cache which retains around `numEvents` events (default 100).
    init (numEvents: Int = 100) {
        cache.totalCostLimit = numEvents
    }

    /// Look up a cache result for an `meta.last_event` call.
    func lookup(rpc proc: String, _ args: WampArgs) -> TopicEvent? {
        if let (topic, originator) = LastEventCache.eventParams(proc, args) {
            return lastMessage(from: originator, sentIn: topic)
        } else {
            return nil
        }
    }

    /// Look up the last message sent by `originator` in `topic`.
    func lastMessage(from originator: String, sentIn topic: String) -> TopicEvent? {
        let event = cache.object(forKey: key(topic, originator) as NSString)
        return event?.value
    }

    /// Store the `event` returned by a call to `rpc`. Returns `true` if stored.
    func store(event: TopicEvent, rpc proc: String, args: WampArgs) {
        if let (metaTopic, _) = LastEventCache.eventParams(proc, args) {
            store(event: event, topic: metaTopic)
        }
    }

    /// Store `event` in the cache. `event` must have an originator. Returns `true` if stored.
    func store(event: TopicEvent, topic: String) {
        if let originator = event.originator {
            cache.setObject(Box(event), forKey: key(topic, originator) as NSString)
        }
    }

    /// Request `topic` to be removed from the cache at the end of the main loop.
    @available(*, deprecated: 1.0, message: "Functionality removed, is now a no-op")
    func void(topic: String) {
        return
    }

    private static func eventParams(_ proc: String, _ args: WampArgs) -> (metaTopic: String, originator: String)? {
        guard let metaTopic = args[safe: 0] as? String, let originator = args[safe: 1] as? String,
            proc == "meta.last_event" else {
                return nil
        }

        return (metaTopic, originator)
    }

    private func key(_ topic: String, _ originator: String) -> String {
        return [topic, originator].joined()
    }
}
