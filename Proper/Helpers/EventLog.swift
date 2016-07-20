//
//  EventLog.swift
//  Proper
//
//  Created by Elliott Williams on 7/20/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

func logSignalEvent(identifier: String, event: String, fileName: String, functionName: String, lineNumber: Int) {
    NSLog("[\(identifier)] \(event)")
}