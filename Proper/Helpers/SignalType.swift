//
//  SignalType.swift
//  Proper
//
//  Created by Elliott Williams on 7/12/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Argo
import Result

// MARK: Value is AnyObject
extension SignalType where Value: AnyObject, ReactiveCocoa.Error == ProperError {
    /// Attempt to decode an `AnyObject` to the model given.
    internal func decode<M: Decodable>(as: M.Type) -> Signal<M.DecodedType, ProperError> {
        return attemptMap { object in
            let decoded = M.decode(JSON(object))
            switch decoded {
            case Decoded.failure(let error):
                return .failure(.decodeFailure(error))
            case Decoded.success(let model):
                return .success(model)
            }
        }
    }
}

extension SignalProducerType where Value: AnyObject, ReactiveCocoa.Error == ProperError {
    /// Attempt to decode an `AnyObject` to the model given.
    internal func decodeAs<M: Decodable>(_: M.Type) -> SignalProducer<M.DecodedType, ProperError> {
        return lift { $0.decodeAs(M) }
    }
}


// MARK: Value is Collection
extension SignalType where Value: Collection, Value.Iterator.Element: AnyObject, ReactiveCocoa.Error == ProperError {
    /// Attempt to decode each member of a list to the `to` type. If *any* decode successfully, an array of successfully
    /// decoded models will be forwarded.
    internal func decodeAnyAs<M: Decodable>(_: M.Type) -> Signal<[M.DecodedType], ProperError> {
        return attemptMap { list in
            let decoded = list.map(JSON.init).flatMap(M.decode)
            let errors = decoded.flatMap { $0.error }
            let models = decoded.flatMap { $0.value }

            // If some models were decoded, or if no models were passed in the list to begin with, the prodecure
            // succeeded.
            if !models.isEmpty || list.isEmpty {
                return .success(models)
            } else {
                return .failure(.decodeFailures(errors: errors))
            }
        }
    }
}

extension SignalProducerType where Value: Collection, Value.Iterator.Element: AnyObject, ReactiveCocoa.Error == ProperError {
    /// Attempt to decode each member of a list to the `to` type. If *any* decode successfully, an array of successfully
    /// decoded models will be forwarded.
    internal func decodeAnyAs<M: Decodable>(_: M.Type) -> SignalProducer<[M.DecodedType], ProperError> {
        return lift { $0.decodeAnyAs(M) }
    }
}


// MARK: Value is Optional
extension SignalType where Value: OptionalType, ReactiveCocoa.Error: ErrorProtocol {
    /// Unwrap the optional value in the signal, or produce an error by calling the closure given.
    internal func unwrapOrSendFailure(_ error: ReactiveCocoa.Error) -> Signal<Value.Wrapped, ReactiveCocoa.Error> {
        return attemptMap { value in
            if let value = value.optional {
                return .success(value)
            } else {
                return .failure(error)
            }
        }
    }
}

extension SignalProducerType where Value: OptionalType, ReactiveCocoa.Error: ErrorProtocol {
    internal func unwrapOrSendFailure(_ error: ReactiveCocoa.Error) -> SignalProducer<Value.Wrapped, ReactiveCocoa.Error> {
        return lift { $0.unwrapOrSendFailure(error) }
    }
}


// MARK: Any signal
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
