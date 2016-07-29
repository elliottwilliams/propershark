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
    /// Distinguishes entities of this type within Proper Shark
    static var namespace: String { get }

    /// The value of this model's identifying attribute
    var identifier: Identifier { get }

    /// WAMP channel name for this model
    var topic: String { get }

    /// Returns the WAMP channel name for the given model. By default, this is implemented using the model's `namespace`
    /// and `identifier`.
    static func topicFor(identifier: Identifier) -> String

    // The fully-qualified name of this object type as it exists on Shark
    static var fullyQualified: String { get }
}

/// Test model identifiers for equality.
func ==<M: Model>(a: M, b: M) -> Bool {
    return a.identifier == b.identifier
}

extension Model {   
    static func topicFor(identifier: Identifier) -> String {
        return "\(Self.namespace).\(identifier)"
    }
}
