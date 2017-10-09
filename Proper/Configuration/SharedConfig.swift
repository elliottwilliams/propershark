//
//  SharedConfig.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation

struct SharedAppConfig: AppConfig {
  let key = "proper"
  let name = "Proper Shark"
}

struct SharedLoggingConfig: LoggingConfig {
  let ignoreSignalProducers = Set([
    "MDWamp.subscribeWithSignal",
    "MDWamp.callWithSignal",
    "Connection.connectionProducer",
    "Connection.subscribe",
    "MutableRoute.producer",
    "Timetable",
    ])
  let logJSON = false
}
