//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct Config {
    struct agency {
        static let key = "citybus"
        static let name = "CityBus"
        static let region = MKCoordinateRegionMakeWithDistance(
            CLLocationCoordinate2D(latitude: 40.4206761, longitude: -86.8966437), 4730, 7840)
        static let timeResolution = TimeInterval(30)
    }

    struct app {
        static let key = "proper"
        static let name = "Proper Shark"
    }

    struct connection {
        static let server = URL(string: "ws://shark-nyc1.transio.us:8080/ws")!
        static let realm = "realm1"
    }

    struct logging {
        static let ignoreSignalProducers = Set([
            "MDWamp.subscribeWithSignal",
            "MDWamp.callWithSignal",
            "Connection.connectionProducer",
            "Connection.subscribe",
            "MutableRoute.producer"
        ])
        static let logJSON = false
    }

    struct ui {
        static let defaultBadgeColor = UIColor.gray
    }
}
