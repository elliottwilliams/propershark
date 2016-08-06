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

/// Encapsulations of Models that know how to more information about the entity they contain, and how to respond
/// to changes in that entity's non-identifying properties. MutableModels are used in controllers, where their properties
/// can be bound to, with loading and availability abstracted away.
protocol MutableModel: class, Hashable {
    associatedtype FromModel: Model

    /// The most recent static model applied to this instance.
    var source: FromModel { get set }
    
    /// The mutable model should know its model's identifier, and the identifier should be immutable. (a model with a
    /// different identifier cannot be applied; it is a different model altogether.)
    var identifier: FromModel.Identifier { get }
    var topic: String { get }

    /// Connects to Shark and sends updates for this entity to the model's properties. Properties of MutableModels are
    /// bound at initialization to their producer, so it should only be accessed directly to listen for all changes to a
    /// model that come in.
    var producer: SignalProducer<FromModel, NoError> { get set }
    
    /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
    init(from _: FromModel, delegate: MutableModelDelegate, connection: ConnectionType)
    var delegate: MutableModelDelegate { get }
    
    /// Update state to match the model given. Returns a failure result if the model given doesn't have the same
    /// identifier.
    func apply(_: FromModel) -> Result<(), PSError>

    var connection: ConnectionType { get }
    var hashValue: Int { get }
}

extension MutableModel {

    /// Returns a property obtained by calling `accessor` with this model's `source` instance.
    internal func lazyProperty<T>(accessor: (FromModel) -> T) -> MutableProperty<T> {
        return MutableProperty(accessor(self.source))
    }

    /// Create a MutableModel from a static model and attach it to the calling MutableModel's delegate.
    internal func attachMutable<M: MutableModel>(from model: M.FromModel) -> M {
        return M(from: model, delegate: self.delegate, connection: self.connection)
    }

    /// Attempt state to match the model given. Convenience form that returns Void.
    func apply(model: FromModel) {
        self.apply(model) as Result
    }

    /// Create and insert new MutableModels to a given set, remove old ones, and apply changes from
    /// persistent ones.
    func applyChanges<M: MutableModel>(to mutableSet: MutableProperty<Set<M>?>, from new: Set<M.FromModel>?) {
        // Don't proceed unless we have a set to apply.
        guard let new = new else { return }

        mutableSet.modify { mutables in
            // Initialize to an empty set if nil.
            var mutables = mutables ?? Set()

            // For each stored mutable model...
            for model in mutables {
                if let idx = new.indexOf(model.source) {
                    // ...apply changes from a corresponding static model in `new`...
                    model.apply(new[idx])
                } else {
                    // ...otherwise, remove it.
                    mutables.remove(model)
                }
            }

            // Then, insert new MutableModels for models in `new` but not in `mutables`.
            new.subtract(Set(mutables.map { $0.source }))
                .forEach { mutables.insert(attachMutable(from: $0)) }

            return mutables
        }
    }

    func applyChanges<M: MutableModel>(to mutableSet: MutableProperty<Set<M>?>, from new: [M.FromModel]?) {
        return applyChanges(to: mutableSet, from: Set(new ?? []))
    }

    var hashValue: Int { return self.identifier.hashValue }
}

protocol MutableModelDelegate {
    /// Called whenever a model's producer encounters an unrecoverable error.
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError)
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
