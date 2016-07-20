//
//  Model.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

protocol Model: Equatable {
    associatedtype Identifier: Equatable
    static var namespace: String { get }
    var identifier: Identifier { get }
    
    var topic: String { get }
    static func topicFor(identifier: Identifier) -> String
}

func ==<M: Model>(a: M, b: M) -> Bool {
    return a.identifier == b.identifier
}

extension Model {
    /// Return the name of the property of the identifying element by reflecting on the model.
    func identifierName() -> String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.value as? Identifier != nil {
                return child.label!
            }
        }
        
        // If no identifying element found above...
        fatalError("Model does not have an identifier.")
    }
    
    func isFullyDefined() -> Bool {
        let mirror = Mirror(reflecting: self)
        // Ensure no named child properties...
        return mirror.children.filter { $0.label != nil }
            // ...have nil values
            .filter { $0.value == nil }.isEmpty
    }
    
    static func topicFor(identifier: Identifier) -> String {
        return "\(Self.namespace).\(identifier)"
    }
}
