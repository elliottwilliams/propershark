//
//  Dev.swift
//  Proper
//
//  Created by Elliott Williams on 6/22/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

// Dictionary that stores configurations for the config lookup/registration functions. It should have an entry for every configuration struct defined below
var configEnvironments: [String:Configuration.Type] = [
    "dev": Dev.self
]

struct Dev: Configuration {
    static var environment = "dev"
    static var agency = "citybus"
    static var connection = (
        server: NSURL(string: "ws://localhost:8080/ws")!,
        realm: "realm1"
    )
}