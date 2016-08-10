//
//  EventLog.swift
//  Proper
//
//  Created by Elliott Williams on 7/20/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

func logSignalEvent(config: Config) -> (identifier: String, event: String, fileName: String, functionName: String, lineNumber: Int) -> () {
    return { identifier, event, fileName, functionName, lineNumber in
        if config.ignoreSignalProducers.contains(identifier) {
            return
        }
        
        let maxIdx = event.startIndex.advancedBy(min(250, event.characters.count))
        let truncated = event.substringToIndex(maxIdx)
        NSLog("[\(identifier)] \(truncated)")
    }
}