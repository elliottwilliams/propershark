//
//  Model.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo

protocol Model: Hashable, CustomStringConvertible {
  associatedtype Identifier: Hashable

  /// Distinguishes entities of this type within Proper Shark
  static var namespace: String { get }

  /// The value of this model's identifying attribute
  var identifier: Identifier { get }

  /// WAMP channel name for this model
  var topic: String { get }

  /// Returns the WAMP channel name for the given model. By default, this is implemented using the model's `namespace`
  /// and `identifier`.
  static func topic(for: Identifier) -> String

  // The fully-qualified name of this object type as it exists on Shark
  static var fullyQualified: String { get }

  init(id: Identifier)

  var hashValue: Int { get }
}

/// Test model identifiers for equality.
func ==<M: Model>(a: M, b: M) -> Bool {
  return a.identifier == b.identifier
}

extension Model {
  /// Returns the WAMP topic corresponding to an ID from this model.
  static func topic(for id: Identifier) -> String {
    return "\(Self.namespace).\(id)"
  }
  /// Returns a model ID string without the fully qualified prefix.
  /// Example: `Shark::Vehicle::BUS123 -> BUS123`
  static func unqualify(fullyQualified id: String) -> String {
    return id.replacingOccurrences(of: Self.fullyQualified + "::", with: "")
  }
  /// Returns a model ID string without the namespace.
  /// Example: `routes.1A -> 1A`
  static func unqualify(namespaced id: String) -> String {
    return id.replacingOccurrences(of: Self.namespace + ".", with: "")
  }

  var description: String { return String(describing: Self.self) + "(\(self.identifier))" }
  var hashValue: Int { return self.identifier.hashValue }
}

extension Model where Identifier: Decodable, Identifier.DecodedType == Identifier {
  /// Decode an "identifier" key from the given JSON.
  static func decodeIdentifier(_ json: JSON) -> Decoded<Identifier> {
    return (json <| "identifier")
  }
}

extension Model where Identifier == String {
  /// Decode an "identifier" key from the given JSON and its namespace prefix.
  static func decodeNamespacedIdentifier(_ json: JSON) -> Decoded<Identifier> {
    return decodeIdentifier(json).map { Self.unqualify(namespaced: $0) }
  }
}
