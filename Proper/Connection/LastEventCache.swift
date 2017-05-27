//
//  LastEventCache.swift
//  Proper
//
//  Created by Elliott Williams on 9/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

/// Manages storage, retrieval, and expiration of TopicEvents keyed by the originator and topic.
class LastEventCache: NSObject {
    private var cache = [String: [String: TopicEvent]]()
    private var voids = [String: DispatchWorkItem]()

    /// Look up the last message sent by `originator` in `topic`.
    func lastEvent(from originator: String, sentIn topic: String) -> TopicEvent? {
        return cache[topic]?[originator]
    }

    /// Store `event` in the cache. `event` must have an originator. Returns `true` if stored.
    func store(event: TopicEvent, from topic: String) {
        if let originator = event.originator {
            voids[topic]?.cancel()
            if var topic = cache[topic] {
                topic[originator] = event
            } else {
                cache[topic] = [originator: event]
            }
        }
    }

    /// Informs the cache that a particular `lastEvent` will no longer be updated and will no longer be guaranteed valid. 
    func expire(topic: String) {
        let action = DispatchWorkItem { [weak self] in
            self?.cache[topic] = nil
            self?.voids[topic] = nil
        }
        voids[topic] = action
        DispatchQueue.main.async(execute: action)
    }
}
