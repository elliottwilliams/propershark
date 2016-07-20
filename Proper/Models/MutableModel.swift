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

protocol MutableModel {
    associatedtype FromModel: Model
    
    /**
     The mutable model should know its model's identifier, and the identifier should be immutable. (a model with a
     different identifier cannot be applied; it is a different model altogether.)
     */
    var identifier: FromModel.Identifier { get }
    var topic: String { get }
    
    /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
    init(from _: FromModel)
    
    /// Update state to match the model given. Implementations may throw an error if a given model cannot be applied.
    func apply(_: FromModel) -> Result<(), PSError>
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

/// Return status from the modify mutable property operator (`<-`).
enum ModifyPropertyResult<T> {
    case modifiedValue(T)
    case unmodified
}