//
//  Date.swift
//  Proper
//
//  Created by Elliott Williams on 1/8/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

extension NSDate: Decodable {
    public static func decode(json: JSON) -> Decoded<NSDate> {
        // Decode `json` as a string and pass that string to Timetable's date formatter. Wrap the optional Date it
        // returns in a Decoded type.
        return Timetable.formatter.dateFromString
            <^> String.decode(json)
            >>- Decoded<NSDate>.fromOptional
    }
}

extension NSDate: Comparable {
    // Comparison function defined globally below.
}

public func < (a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == .OrderedAscending
}
