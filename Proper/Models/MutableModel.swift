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
protocol MutableModel: Hashable {
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
    var producer: SignalProducer<FromModel, NoError> { get }
    
    /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
    init(from _: FromModel, delegate: MutableModelDelegate)
    var delegate: MutableModelDelegate { get }
    
    /// Update state to match the model given. Implementations may throw an error if a given model cannot be applied.
    func apply(_: FromModel) -> Result<(), PSError>

    var hashValue: Int { get }
}

extension MutableModel {
    /// Returns a property obtained by calling `accessor` with this model's `source` instance. The property is bound
    /// to this model's `producer`. The producer is not started automatically.
    internal func lazyProperty<T>(accessor: (FromModel) -> T) -> MutableProperty<T> {
        let property = MutableProperty(accessor(self.source))
        self.producer.map(accessor).on(next: { property.value = $0 })
        return property
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

/// Makes updates from a immutable value to a mutable property containing that value.
infix operator <- {}

/**
 Modify a property `mutable` if it differs from `source`.
 Returns a `Result`, which is successful if the modification was made.
 */
internal func <- <T: Equatable>(mutable: MutableProperty<T>, source: T) -> ModifyPropertyResult<T> {
    if source != mutable.value {
        return .modifiedValue(mutable.swap(source))
    }
    return .unmodified
}

/**
 Modify a property `mutable` if it differs from `source`, **and if `source` is not nil**.
 Because of the latter requirement, once a property has been given a non-nil value, it cannot be made nil again.
 Returns a `Result`, which is successful if the modification was made.
 */
internal func <- <T: Equatable>(mutable: MutableProperty<T?>, source: T?) -> ModifyPropertyResult<T> {
    if let unwrapped = source {
        return mutable <- unwrapped
    }
    return .unmodified
}

/// Modify `mutable` if any elements in `source` are different.
internal func <- <T: Equatable>(mutable: MutableProperty<[T]>, source: [T]) -> ModifyPropertyResult<[T]> {
    if source.elementsEqual(mutable.value) {
        return .modifiedValue(mutable.swap(source))
    }
    return .unmodified
}

internal func <- <T: Equatable>(mutable: MutableProperty<[T]?>, source: [T]?) -> ModifyPropertyResult<[T]?> {
    if let unwrapped = source {
        return mutable <- unwrapped
    }
    return .unmodified
}

/// Return status from the modify mutable property operator (`<-`).
enum ModifyPropertyResult<T> {
    case modifiedValue(T)
    case unmodified
}