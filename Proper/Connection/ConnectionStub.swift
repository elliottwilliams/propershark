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

class ConnectionStub: Connection {
    var callMap: [String: MDWampResult] = [:]
    
    func on(call procedure: String, send result: MDWampResult) {
        callMap[procedure] = result
    }
    
    func on(call procedure: String, sendArgs args: [AnyObject], kwargs: [NSObject: AnyObject]) {
        let result = MDWampResult()
        result.arguments = args
        result.argumentsKw =  kwargs
        result.options = [:]
        callMap[procedure] = result
    }
    
    override func call(procedure: String, args: [AnyObject], kwargs: [NSObject : AnyObject]) -> SignalProducer<MDWampResult, PSError> {
        return SignalProducer<MDWampResult, PSError> { observer, _ in
            if let result = self.callMap[procedure] {
                result.request = NSNumber(int: rand())
                observer.sendNext(result)
            } else {
                observer.sendFailed(PSError(code: .mdwampError))
            }
        }
    }
}