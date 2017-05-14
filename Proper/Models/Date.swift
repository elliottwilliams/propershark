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

extension Date: Decodable {
    public static func decode(_ json: JSON) -> Decoded<Date> {
        // Decode `json` as a string and pass that string to Timetable's date formatter. Wrap the optional Date it
        // returns in a Decoded type.
        return Timetable.formatter.date(from:)
            <^> String.decode(json)
            >>- Decoded<Date>.fromOptional
    }
}

extension Date: Comparable {
    // Comparison function defined globally below.
}

public func < (a: Date, b: Date) -> Bool {
    return a.compare(b) == .orderedAscending
}
