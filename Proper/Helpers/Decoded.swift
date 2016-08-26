//
//  Decoded.swift
//  Proper
//
//  Created by Elliott Williams on 8/23/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo

extension Decoded {
    /// Calls a throwing function that produces successful values of type `T`. Caught exceptions will be transformed
    /// into `.Failure`.
    static func attempt(@autoclosure fn: () throws -> Decoded<T>) -> Decoded<T> {
        do {
            return try fn()
        } catch {
            return .customError("\(error)")
        }
    }
}