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

protocol MutableModel {
    associatedtype Model
    
    /// Initialize all `MutableProperty`s of this `MutableModel` from a corresponding model.
    init(from _: Model)
    
    /// Update state to match the given model.
    func apply(_: Model) throws
}

/// Makes updates from a immutable value to a mutable property containing that value.
infix operator <- {}

/**
 Modify a property `mutable` if it differs from `source`.
 Returns a `Result`, which is successful if the modification was made.
 */
internal func <- <T: Equatable>(mutable: MutableProperty<T>, source: T) -> ModifyPropertyResult<T> {
    if source != mutable.value {
        return .modifiedFrom(mutable.swap(source))
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

/// Return status from the modify mutable property operator (`<-`).
enum ModifyPropertyResult<T> {
    case modifiedFrom(T)
    case unmodified
}