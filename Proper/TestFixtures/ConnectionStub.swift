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
    var callMap: [String: MDWampResult] = [:]
    
    
    class Channel {
        typealias SignalType = Signal<(args: WampArgs, kwargs: WampKwargs), NoError>
        typealias ObserverType = Observer<(args: WampArgs, kwargs: WampKwargs), NoError>
        
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
                let (signal, observer) = Signal<(args: WampArgs, kwargs: WampKwargs), NoError>.pipe()
                let channel = Channel(topic, signal, observer)
                channels[topic] = channel
                return channel
            }
        }
    }
    
    func on(call procedure: String, send result: MDWampResult) {
        callMap[procedure] = result
    }
    
    func on(call procedure: String, sendArgs args: WampArgs, kwargs: WampKwargs) {
        let result = MDWampResult()
        result.arguments = args
        result.argumentsKw =  kwargs
        result.options = [:]
        callMap[procedure] = result
    }
    
    func publish(to topic: String, args: WampArgs, kwargs: WampKwargs) {
        let channel = Channel.findOrCreate(topic)
        channel.observer.sendNext((args: args, kwargs: kwargs))
    }
    
    func call(procedure: String, args: WampArgs, kwargs: WampKwargs) -> SignalProducer<MDWampResult, PSError> {
        return SignalProducer<MDWampResult, PSError> { observer, _ in
            if let result = self.callMap[procedure] {
                result.request = NSNumber(int: rand())
                observer.sendNext(result)
            } else {
                observer.sendFailed(PSError(code: .mdwampError))
            }
        }.logEvents(identifier: "ConnectionStub#call")
    }
    
    func subscribe(topic: String) -> SignalProducer<MDWampEvent, PSError> {
        let channel = Channel.findOrCreate(topic)
        return SignalProducer<MDWampEvent, PSError> { observer, disposable in
            // Reduce the subscriber count on this channel, potentially deleting it
            disposable.addDisposable() { Channel.leave(topic) }
            
            // Map emits from the channel to MDWampEvents...
            channel.signal.map { (args: WampArgs, kwargs: WampKwargs) in
                let event = MDWampEvent()
                event.arguments = args
                event.argumentsKw = kwargs
                return event
            }
            // ...promote the signal to look as if it generates PSErrors...
            .promoteErrors(PSError)
            // ...and forward to this subscriber's observer
            .observe(observer)
        }
    }
}