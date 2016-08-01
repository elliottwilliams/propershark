//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

struct Config {
    static let sharedInstance = Config()
    
    let environment = Environments.dev
    enum Environments {
        case dev
        case test
        case prod
    }
    
    let agency = (
        key: "citybus",
        name: "CityBus"
    )
    let app = (
        key: "proper",
        name: "Proper Shark"
    )
    let connection = (
        server: NSURL(string: "ws://162.243.171.187:8080/ws")!,
        realm: "realm1"
    )
}