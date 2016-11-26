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
    let cache = NSCache()

    struct VoidState {
        var topics = Set<String>()
        var queued = false
    }
    var voidState = VoidState()

    /// Create a cache which retains around `numEvents` events (default 100).
    init (numEvents: Int = 100) {
        cache.totalCostLimit = numEvents
    }

    /// Look up a cache result for an `meta.last_event` call.
    func lookup(rpc proc: String, _ args: WampArgs) -> TopicEvent? {
        if let (metaTopic, originator) = LastEventCache.eventParams(proc, args) {
            return lookup(metaTopic, originator: originator)
        } else {
            return nil
        }
    }

    /// Look up the last message sent by `originator` in `topic`.
    func lookup(topic: String, originator: String) -> TopicEvent? {
        let channel = cache.objectForKey(topic) as? [String: Box<TopicEvent>]
        return channel?[originator]?.value
    }

    /// Store the `event` returned by a call to `rpc`. Returns `true` if stored.
    func store(rpc proc: String, args: WampArgs, event: TopicEvent) -> Bool {
        if let (metaTopic, _) = LastEventCache.eventParams(proc, args) {
            return store(metaTopic, event: event)
        } else {
            return false
        }
    }

    /// Store `event` in the cache. `event` must have an originator. Returns `true` if stored.
    func store(topic: String, event: TopicEvent) -> Bool {
        guard let originator = event.originator else {
            return false
        }

        // If `topic` was slated to be voided from the cache, remove it from the void topics list.
        voidState.topics.remove(topic)

        // If there is already a listing for this topic, add this event to it; otherwise create a dictionary
        // representing the topic. Update the cost to represent the number of messages cached for a channel.
        if var channel = cache.objectForKey(topic) as? [String: Box<TopicEvent>] {
            channel[originator] = Box(event)
            cache.setObject(channel, forKey: originator, cost: channel.count)
        } else {
            let channel = [originator: Box(event)]
            cache.setObject(channel, forKey: originator, cost: 1)
        }

        return true
    }

    /// Request `topic` to be removed from the cache at the end of the main loop.
    func void(topic: String) {
        voidState.topics.insert(topic)
        if !voidState.queued {
            NSOperationQueue.mainQueue().addOperationWithBlock(processVoids)
            voidState.queued = true
        }
    }

    private func processVoids() {
        while let topic = voidState.topics.popFirst() {
            cache.removeObjectForKey(topic)
        }
        voidState.queued = false
    }

    private static func eventParams(proc: String, _ args: WampArgs) -> (metaTopic: String, originator: String)? {
        guard let metaTopic = args[safe: 0] as? String, originator = args[safe: 1] as? String where
            proc == "meta.last_event" else {
                return nil
        }

        return (metaTopic, originator)
    }
}
