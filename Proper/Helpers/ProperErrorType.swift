//
//  ProperErrorType.swift
//  Proper
//
//  Created by Elliott Williams on 6/30/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

/// Every error generated by Proper conforms to this protocol.
protocol ProperErrorType: ErrorType {
    /// 3 to 7 word description of the error.
    var title: String { get }
    /// 1 to 4 sentence description of the error.
    var message: String { get }
    /// Technical information that will be shown in debug versions of the application.
    var debugMessage: String? { get }
}

extension ProperErrorType {
    // Default values for errors:
    var debugMessage: String? { return nil }

    // Message strings that are intended to be shared among ProperError implementations:
    static var genericBadData: String { return "Our server sent us some information that could not be understood." }
    static var genericTitle: String { "Something went wrong" }
}

/// When a value that represents *any* kind of ProperErrorType is needed, wrap a ProperErrorType value in this container
/// struct.
///
/// Note that it is perfectly legal to contain a ProperError value inside another.
struct ProperError: ProperErrorType {
    let title: String
    let message: String
    let debugMessage: String?

    init<T: ProperErrorType> (_ error: T) {
        title = error.title
        message = error.message
        debugMessage = error.debugMessage
    }
}