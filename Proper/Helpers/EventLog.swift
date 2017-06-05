//
//  EventLog.swift
//  Proper
//
//  Created by Elliott Williams on 7/20/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

func logSignalEvent(identifier: String, event: String, fileName: String, functionName: String, lineNumber: Int) -> () {
  if Config.logging.ignoreSignalProducers.contains(identifier) {
    return
  }

  let maxIdx = event.characters.index(event.startIndex, offsetBy: min(250, event.characters.count))
  let truncated = event.substring(to: maxIdx)
  NSLog("[\(identifier)] \(truncated)")
}
