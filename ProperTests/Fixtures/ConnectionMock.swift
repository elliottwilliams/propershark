//
//  ConnectionMock.swift
//  Proper
//
//  Created by Elliott Williams on 7/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import MDWamp
import ReactiveCocoa
import Result
@testable import Proper

class ConnectionMock: ConnectionType {
    var callMap: [String: TopicEvent] = [:]
    var onSubscribe: (String -> ())?

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

        func leave(id: String) {
            if let topic = find(id) {
                topic.subscribers -= 1
                if topic.subscribers < 1 {
                    // Close the signal and delete the channel
                    topic.observer.sendCompleted()
                    topics[id] = nil
                }
            }
        }

        func find(id: String) -> Topic? {
            return topics[id]
        }
        
        func findOrCreate(id: String) -> Topic {
            if let topic = find(id) {
                return topic
            } else {
                let topic = Topic(id)
                topics[id] = topic
                return topic
            }
        }
    }

    init(onSubscribe: (String -> ())? = nil) {
        self.onSubscribe = onSubscribe
    }
    
    func on(proc: String, send event: TopicEvent) {
        callMap[proc] = event
    }
    
    func publish(to id: String, event: TopicEvent) {
        if let topic = server.find(id) {
            topic.observer.sendNext(event)
        }
    }
    
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> SignalProducer<TopicEvent, ProperError> {
        return SignalProducer<TopicEvent, ProperError> { observer, _ in
            if let event = self.callMap[procedure] {
                observer.sendNext(event)
            }
        }.logEvents(identifier: "ConnectionMock.call(\(procedure))", logger: logSignalEvent)
    }
    
    func subscribe(id: String) -> SignalProducer<TopicEvent, ProperError> {
        let topic = server.findOrCreate(id)
        topic.subscribers += 1
        self.onSubscribe?(id)
        return SignalProducer<TopicEvent, ProperError> { observer, disposable in
            // Upon disposal, reduce the subscriber count on this channel, potentially deleting it.
            disposable.addDisposable() { self.server.leave(id) }
            
            // Map channel errors to PSErrors...
            topic.signal.promoteErrors(ProperError)
            // ...and forward to this subscriber's observer
            .observe(observer)
        }.logEvents(identifier: "ConnectionMock.subscribe(\(id))", logger: logSignalEvent)
    }

    func subscribed(topic: String) -> Bool {
        return (server.find(topic)?.subscribers > 0) ?? false
    }
}