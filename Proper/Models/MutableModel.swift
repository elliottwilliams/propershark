//
//  Mutable.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Curry
import Result
import Argo

/// Encapsulations of Models that know how to more information about the entity they contain, and how to respond
/// to changes in that entity's non-identifying properties. MutableModels are used in controllers, where their properties
/// can be bound to, with loading and availability abstracted away.
protocol MutableModel: class, Hashable {
    associatedtype FromModel: Model
    
    /// The mutable model should know its model's identifier, and the identifier should be immutable. (a model with a
    /// different identifier cannot be applied; it is a different model altogether.)
    var identifier: FromModel.Identifier { get }
    var topic: String { get }

    /// A producer that, when started, connects to Shark and subscribes to this model's topic. Calls `handleEvent` to
    /// apply updates to the model's properties as they are emitted. Additional signals can be created to receive
    /// failures or inject side effects to topic events.
    var producer: SignalProducer<TopicEvent, PSError> { get set }
    func handleEvent(event: TopicEvent) -> Result<(), PSError>
    
    /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
    init(from _: FromModel, delegate: MutableModelDelegate, connection: ConnectionType)
    var delegate: MutableModelDelegate { get }
    
    /// Update state to match the model given. Throws PSError if a consistency check fails.
    func apply(_: FromModel) throws

    var connection: ConnectionType { get }

    var hashValue: Int { get }
}

extension MutableModel {

    /// Create a MutableModel from a static model and attach it to the calling MutableModel's delegate.
    internal func attachMutable<M: MutableModel>(from model: M.FromModel) -> M {
        return M(from: model, delegate: self.delegate, connection: self.connection)
    }

    /// Create and insert new MutableModels to a given set, remove old ones, and apply changes from
    /// persistent ones.
    func attachOrApplyChanges<M: MutableModel>(to mutableSet: MutableProperty<Set<M>?>,
                      from new: [M.FromModel.Identifier: M.FromModel]?) throws
    {
        // Attempt to unwrap `new` and create a mutable copy of it.
        guard var new = new else { return }

        try mutableSet.modify { mutables in
            // Initialize to an empty set if nil.
            var mutables = mutables ?? Set()

            // For each stored mutable model...
            for model in mutables {
                if let replacement = new.removeValueForKey(model.identifier) {
                    // ...apply changes from a corresponding static model in `new`...
                    try model.apply(replacement)
                } else {
                    // ...otherwise, remove it.
                    mutables.remove(model)
                }
            }

            // Remaining models in `new` are new to the set. Attch MutableModels for them.
            new.forEach { id, model in mutables.insert(attachMutable(from: model)) }

            return mutables
        }
    }

    func attachOrApplyChanges<C: CollectionType, M: MutableModel where C.Generator.Element == M.FromModel>
        (to mutableSet: MutableProperty<Set<M>?>, from new: C?) throws
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
            property.value = attachMutable(from: update) as M
        }
    }

    var hashValue: Int { return self.identifier.hashValue }
}

protocol MutableModelDelegate {
    /// Called when a model's producer receives a topic event it does not handle.
    func mutableModel<M: MutableModel>(model: M, receivedTopicEvent event: TopicEvent)
}

extension MutableModelDelegate {
    // Default implementation for `receivedTopicEvent` delegate method
    func mutableModel<M: MutableModel>(model: M, receivedTopicEvent event: TopicEvent) {
        // do nothing
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
infix operator <- {}

/// Makes updates from a immutable array or collection to a mutable property containing that value.
infix operator <-| {}

/// Modify `mutable` if `source` is non-nil.
internal func <- <T: Equatable>(mutable: MutableProperty<T?>, source: T?) -> ModifyPropertyResult<T?> {
    if let value = source where value != mutable.value {
        return .modifiedFrom(mutable.swap(value))
    }
    return .unmodified
}

/// Modify `mutable` if any elements in `source` are different.
internal func <-| <C: CollectionType, T: Equatable where C.Generator.Element == T>(
    mutable: MutableProperty<C?>, source: C?) -> ModifyPropertyResult<C?>
{
    if let source = source where mutable.value == nil || source.elementsEqual(mutable.value!) {
        return .modifiedFrom(mutable.swap(source))
    }
    return .unmodified
}

/// Modify `mutable` if any elements in `source` are different, by building a Set from `source`.
internal func <-| <T: Hashable>(mutable: MutableProperty<Set<T>?>, source: [T]?) -> ModifyPropertyResult<Set<T>?> {
    return source.map { mutable <-| Set($0) } ?? .unmodified
}

/// Return status from the modify mutable property operator (`<-`).
enum ModifyPropertyResult<T> {
    case modifiedFrom(T)
    case unmodified
}
