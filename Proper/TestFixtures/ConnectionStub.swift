//
//  ConnectionStub.swift
//  Proper
//
//  Created by Elliott Williams on 7/6/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import MDWamp
import ReactiveCocoa
import Result

class ConnectionStub: ConnectionType {
    var callMap: [String: TopicEvent] = [:]
    
    
    class Channel {
        typealias SignalType = Signal<TopicEvent, NoError>
        typealias ObserverType = Observer<TopicEvent, NoError>
        
        let topic: String
        let signal: SignalType
        let observer: ObserverType
        var subscribers: Int = 0
        
        static var channels: [String: Channel] = [:]
        
        init(_ topic: String, _ signal: SignalType, _ observer: ObserverType) {
            self.topic = topic
            self.signal = signal
            self.observer = observer
        }
        
        static func leave(topic: String) {
            if let channel = channels[topic] {
                channel.subscribers -= 1
                if channel.subscribers < 1 {
                    // Close the signal and delete the channel
                    channel.observer.sendCompleted()
                    channels[topic] = nil
                }
            }
        }
        
        static func findOrCreate(topic: String) -> Channel {
            if let channel = channels[topic] {
                return channel
            } else {
                let (signal, observer) = Signal<TopicEvent, NoError>.pipe()
                let channel = Channel(topic, signal, observer)
                channels[topic] = channel
                return channel
            }
        }
    }
    
    func on(call procedure: String, send event: TopicEvent) {
        callMap[procedure] = event
    }
    
    func publish(to topic: String, event: TopicEvent) {
        let channel = Channel.findOrCreate(topic)
        channel.observer.sendNext(event)
    }
    
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> SignalProducer<TopicEvent, PSError> {
        return SignalProducer<TopicEvent, PSError> { observer, _ in
            if let event = self.callMap[procedure] {
                observer.sendNext(event)
            } else {
                observer.sendFailed(PSError(code: .mdwampError))
            }
        }.logEvents(identifier: "ConnectionStub.call", logger: logSignalEvent)
    }
    
    func subscribe(topic: String) -> SignalProducer<TopicEvent, PSError> {
        let channel = Channel.findOrCreate(topic)
        return SignalProducer<TopicEvent, PSError> { observer, disposable in
            // Reduce the subscriber count on this channel, potentially deleting it
            disposable.addDisposable() { Channel.leave(topic) }
            
            // Map channel errors to PSErrors...
            channel.signal.promoteErrors(PSError)
            // ...and forward to this subscriber's observer
            .observe(observer)
        }
    }
}