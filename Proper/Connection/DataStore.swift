//
//  DataStore.swift
//  Proper
//
//  Created by Elliott Williams on 6/18/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class DataStore: NSObject {
    func requestModel<M: ModelBase>(id: String) -> SignalProducer<M, NSError> {
        return SignalProducer<M, NSError> { observer, _ in
            observer.sendNext(M.getById("1234"))
            observer.sendCompleted()
        }
    }
    
    /*
    func requestModel<M: Base>(model: M.Type, withId: String) -> Signal<M, NSError> {
        // Get a signal producer for this model
        
        // RPC call to get the model's last update
        
        // Sub to the model's channel
        
        // Bind updates on the model's channel to the observer
        
        //
    }*/
}

protocol ModelBase {
    var namespace: String { get }
    static func getById(id: String) -> Self
}

class ModelRoute: ModelBase {
    let id: String
    let version: String
    let name: String
    let color: String
//    let vehicles: [Int]
    
    var namespace: String { return "route" }
    
    static func getById(id: String) -> Self {
        return self.init(id: id, version: "0", name: "ModelRoute test", color: "blue")
    }
    
    required init(id: String, version: String, name: String, color: String) {
        self.id = id
        self.version = version
        self.name = name
        self.color = color
    }
}