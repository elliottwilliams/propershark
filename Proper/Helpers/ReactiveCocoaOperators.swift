//
//  ReactiveCocoaOperators.swift
//  Proper
//
//  Created by Elliott Williams on 7/12/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Argo
import Result

extension SignalType where Value: AnyObject, Error == PSError {
    /// Attempt to decode an `AnyObject` to the model given.
    internal func decodeAs<M: Decodable>(_: M.Type) -> Signal<M.DecodedType, PSError> {
        return attemptMap { object in
            let decoded = M.decode(JSON(object))
            switch decoded {
            case Decoded.Failure(let error):
                return Result.Failure(PSError(code: .parseFailure, associated: error))
            case Decoded.Success(let model):
                return Result.Success(model)
            }
        }
    }
}

extension SignalProducerType where Value: AnyObject, Error == PSError {
    /// Attempt to decode an `AnyObject` to the model given.
    internal func decodeAs<M: Decodable>(_: M.Type) -> SignalProducer<M.DecodedType, PSError> {
        return lift { $0.decodeAs(M) }
    }
}

extension SignalType where Value: CollectionType, Error == PSError {
    /// Attempt to decode each member of a list to the `to` type. If *any* decode successfully, an array of successfully
    /// decoded models will be forwarded.
    internal func decodeAnyAs<M: Decodable>(_: M.Type) -> Signal<[M.DecodedType], PSError> {
        return attemptMap { list in
            guard list is [AnyObject] else { return .Failure(PSError(code: .parseFailure)) }
            let decoded = list.flatMap { M.decode(JSON($0 as! AnyObject)) }
            let errors = decoded.map { $0.error }
            let models = decoded.flatMap { $0.value }

            // If some models were decoded, or if no models were passed in the list to begin with, the prodecure
            // succeeded.
            if !models.isEmpty || list.isEmpty {
                return .Success(models)
            } else {
                return .Failure(PSError(code: .parseFailure, associated: errors))
            }
        }
    }
}

extension SignalProducerType where Value: CollectionType, Error == PSError {
    /// Attempt to decode each member of a list to the `to` type. If *any* decode successfully, an array of successfully
    /// decoded models will be forwarded.
    internal func decodeAnyAs<M: Decodable>(_: M.Type) -> SignalProducer<[M.DecodedType], PSError> {
        return lift { $0.decodeAnyAs(M) }
    }
}

extension SignalType {
    internal func assumeNoError() -> Signal<Self.Value, NoError> {
        return mapError { error in
            fatalError("Error occured within a signal assumed to never fail: \(error)")
            ()
        }
    }
}

extension SignalProducerType {
    internal func assumeNoError() -> SignalProducer<Self.Value, NoError> {
        return lift { $0.assumeNoError() }
    }
}