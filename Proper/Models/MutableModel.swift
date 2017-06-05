//
//  Mutable.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Curry
import Result
import Argo

/// Encapsulations of Models that know how to more information about the entity they contain, and how to respond
/// to changes in that entity's non-identifying properties. MutableModels are used in controllers, where their properties
/// can be bound to, with loading and availability abstracted away.
protocol MutableModel: class, Hashable, CustomStringConvertible {
  associatedtype FromModel: Model

  /// The mutable model should know its model's identifier, and the identifier should be immutable. (a model with a
  /// different identifier cannot be applied; it is a different model altogether.)
  var identifier: FromModel.Identifier { get }
  var topic: String { get }

  /// A producer that, when started, connects to Shark and subscribes to this model's topic. Calls `handleEvent` to
  /// apply updates to the model's properties as they are emitted. Additional signals can be created to receive
  /// failures or inject side effects to topic events.
  var producer: SignalProducer<TopicEvent, ProperError> { get set }
  func handle(event: TopicEvent) -> Result<(), ProperError>

  /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
  init(from _: FromModel, connection: ConnectionType) throws

  /// Update state to match the model given. Throws ProperError if a consistency check fails.
  func apply(_: FromModel) throws

  /// Decompose the mutable model's current state down to a static model.
  func snapshot() -> FromModel

  var connection: ConnectionType { get }

  var hashValue: Int { get }
}

extension MutableModel {

  /// Create a MutableModel from a static model and attach it to the calling MutableModel's delegate.
  internal func attachMutable<M: MutableModel>(from model: M.FromModel) throws -> M {
    return try M(from: model, connection: self.connection)
  }

  /// Create and insert new MutableModels to a given set, remove old ones, and apply changes from
  /// persistent ones.
  func attachOrApplyChanges<M: MutableModel>(to mutableSet: MutableProperty<Set<M>>,
                            from new: [M.FromModel.Identifier: M.FromModel]?) throws
  {
    // Attempt to unwrap `new` and create a mutable copy of it.
    guard var new = new else { return }

    try mutableSet.modify({ mutables in
      // For each stored mutable model...
      for model in mutables {
        if let replacement = new.removeValue(forKey: model.identifier) {
          // ...apply changes from a corresponding static model in `new`...
          try model.apply(replacement)
        } else {
          // ...otherwise, remove it.
          mutables.remove(model)
        }
      }

      try new.forEach { id, model in
        try mutables.insert(attachMutable(from: model))
      }
    })
    /*try mutableSet.modify { mutables in
     // For each stored mutable model...
     for model in mutables {
     if let replacement = new.removeValue(forKey: model.identifier) {
     // ...apply changes from a corresponding static model in `new`...
     try model.apply(replacement)
     } else {
     // ...otherwise, remove it.
     mutables.remove(model)
     }
     }

     // Remaining models in `new` are new to the set. Attch MutableModels for them.
     try new.forEach { id, model in
     try mutables.insert(attachMutable(from: model))
     }
     return Result.success()
     }*/
  }

  func attachOrApplyChanges<C: Collection, M: MutableModel>
    (to mutableSet: MutableProperty<Set<M>>, from new: C?) throws where C.Iterator.Element == M.FromModel
  {
    guard let new = new else { return }

    let dict: [M.FromModel.Identifier: M.FromModel] = new.reduce([:]) { dict, model in
      var dict = dict
      dict[model.identifier] = model
      return dict
    }
    return try attachOrApplyChanges(to: mutableSet, from: dict)
  }

  func attachOrApply<M: MutableModel>(to property: MutableProperty<M?>, from update: M.FromModel?) throws {
    guard let update = update else { return }
    if let mutable = property.value {
      try mutable.apply(update)
    } else {
      property.value = try attachMutable(from: update) as M
    }
  }

  var description: String { return String(describing: Self.self) + "(\(self.identifier))" }
  var hashValue: Int { return self.identifier.hashValue }

  static func create(from: FromModel, connection: ConnectionType) -> Result<Self, ProperError> {
    return ProperError.capture({ try Self(from: from, connection: connection) })
  }
}

func ==<M: MutableModel>(a: M, b: M) -> Bool {
  return a.identifier == b.identifier
}

func ==<M: MutableModel>(a: M, b: M.FromModel) -> Bool {
  return a.identifier == b.identifier
}

func ==<M: MutableModel>(a: M.FromModel, b: M) -> Bool {
  return a.identifier == b.identifier
}

/// Makes updates from a immutable value to a mutable property containing that value.
infix operator <-

/// Makes updates from a immutable array or collection to a mutable property containing that value.
infix operator <-|

/// Modify `mutable` if `source` is non-nil.
internal func <- <T: Equatable>(mutable: MutableProperty<T?>, source: T?) {
  if let value = source, value != mutable.value {
    mutable.swap(value)
  }
}

/// Modify `mutable` if any elements in `source` are different.
internal func <-| <C: Collection, T: Equatable>(mutable: MutableProperty<C?>, source: C?)
  where C.Iterator.Element == T
{
  if let source = source, mutable.value == nil || source.elementsEqual(mutable.value!) {
    mutable.swap(source)
  }
}

/// Modify `mutable` if any elements in `source` are different, by building a Set from `source`.
internal func <-| <T: Hashable>(mutable: MutableProperty<Set<T>?>, source: [T]?) {
  if let source = source {
    mutable <-| Set(source)
  }
}
