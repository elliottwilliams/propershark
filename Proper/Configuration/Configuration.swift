//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit

struct Config {
    struct agency {
        static let key = "citybus"
        static let name = "CityBus"
    }

    struct app {
        static let key = "proper"
        static let name = "Proper Shark"
    }

    struct connection {
        static let server = NSURL(string: "ws://shark-nyc1.transio.us:8080/ws")!
        static let realm = "realm1"
    }

    static let ignoreSignalProducers = Set(
        arrayLiteral:
        "MDWamp.subscribeWithSignal",
        "MDWamp.callWithSignal",
        "Connection.connectionProducer"
    )

    struct ui {
        static let defaultBadgeColor = UIColor.blueColor()
    }
}