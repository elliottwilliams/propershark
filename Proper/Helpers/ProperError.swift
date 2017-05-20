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

enum ProperError: Error {
    // Connection
    case mdwampError(topic: String, object: Error?)
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
    case locationMonitoringFailed(region: CLRegion?, error: Error)
    case locationDisabled

    case unexpected(Error)

    /// Returns the result of calling `fn`, wrapping any error as a ProperError.
    static func capture<U>(_ fn: () throws -> U) -> Result<U, ProperError> {
        do {
            return try .success(fn())
        } catch let error as ProperError {
            return .failure(error)
        } catch {
            return .failure(.unexpected(error))
        }
    }

    static func from<U>(decoded: Decoded<U>) -> Result<U, ProperError> {
        switch decoded {
        case .success(let v):
            return .success(v)
        case .failure(let e):
            return .failure(.decodeFailure(e))
        }
    }
}
