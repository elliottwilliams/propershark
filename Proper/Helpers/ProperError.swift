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

enum ProperError: ErrorType {
    // Connection
    case mdwampError(topic: String, object: NSError)
    case connectionLost(reason: String)
    case maxConnectionFailures
    case eventParseFailure
    case timeout

    // Model
    case decodeFailure(error: DecodeError)
    case decodeFailures(errors: [DecodeError])
    case stateInconsistency(description: String, within: Any)
    case applyFailure(from: String, onto: String)

    // Location
    case locationMonitoringFailed(region: CLRegion?, error: NSError)
    case locationDisabled

    case unexpected(error: ErrorType)
}
