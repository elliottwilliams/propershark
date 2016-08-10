//
//  EventLog.swift
//  Proper
//
//  Created by Elliott Williams on 7/20/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

func logSignalEvent(identifier: String, event: String, fileName: String, functionName: String, lineNumber: Int) {
    let maxIdx = event.startIndex.advancedBy(min(250, event.characters.count))
    let truncated = event.substringToIndex(maxIdx)
    NSLog("[\(identifier)] \(truncated)")
}