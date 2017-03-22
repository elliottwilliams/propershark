//
//  ProperError.swift
//  Proper
//
//  Created by Elliott Williams on 6/30/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import CoreLocation
import Result

enum ProperError: ErrorType {
    // Connection
    case mdwampError(topic: String, object: NSError)
    case connectionLost(reason: String)
    case maxConnectionFailures
    case eventParseFailure
    case timeout

    // Model
    case decodeFailure(DecodeError)
    case decodeFailures(errors: [DecodeError])
    case stateInconsistency(description: String, within: Any)
    case applyFailure(from: String, onto: String)

    // Location
    case locationMonitoringFailed(region: CLRegion?, error: NSError)
    case locationDisabled

    case unexpected(ErrorType)

    /// Returns the result of calling `fn`, wrapping any error as a ProperError.
    static func capture<U>(fn: () throws -> U) -> Result<U, ProperError> {
        do {
            return try .Success(fn())
        } catch let error as ProperError {
            return .Failure(error)
        } catch {
            return .Failure(.unexpected(error))
        }
    }

    static func fromDecoded<U>(decoded: Decoded<U>) -> Result<U, ProperError> {
        switch decoded {
        case .Success(let v):
            return .Success(v)
        case .Failure(let e):
            return .Failure(.decodeFailure(e))
        }
    }
}
