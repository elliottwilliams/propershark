//
//  ConnectionError.swift
//  Proper
//
//  Created by Elliott Williams on 8/28/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

enum ConnectionError: ProperErrorType {
    case mdwampError(topic: String, object: NSError)
    case connectionLost(reason: String)
    case maxConnectionFailures
    case eventParseFailure

    var title: String { return self.description().title }
    var message: String { return self.description().message }
    var debugMessage: String? {
        switch self {
        case let .mdwampError(topic, object):
            return "\(object.localizedDescription) on \(topic)"
        case let .connectionLost(reason):
            return reason
        default:
            return nil
        }
    }

    private func description() -> (title: String, message: String) {
        switch self {
        case .mdwampError:
            return ("Server connection error", "Our server sent an error message. Check that your Internet connection is functioning and try again.")
        case .connectionLost:
            return ("Connection lost", "We are no longer able to reach to our server.")
        case .maxConnectionFailures:
            return ("Disconnected from servers", "We are unable to communicate with our server. Check that your Internet connection is function and try again.")
        case .eventParseFailure:
            return (ConnectionError.genericTitle, ConnectionError.genericBadData)
        }
    }
}