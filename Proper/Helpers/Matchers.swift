//
//  Matchers.swift
//  Proper
//
//  Created by Elliott Williams on 7/2/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit


/// A string type that pattern matches with the prefix of itself. For example:
///
///     let prefixMatch = "foo.bar" as PrefixMatcher
///     switch prefixMatch {
///     case "foo": ...         // This case matches
///     case "bar": ...         // This case does not match
///     default:    ...
///     }
typealias PrefixMatcher = String
func ~= (pattern: String, value: PrefixMatcher) -> Bool {
    return pattern.hasPrefix(value)
}