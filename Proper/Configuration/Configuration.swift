//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

// All configuration contexts conform to this protocol. Any new config values must be added here first.
protocol Configuration {
    static var environment: String { get }
    static var agency: String { get }
    static var connection: (
        server: NSURL,
        realm: String
    ) { get }
}

// Methods to look up a config from its environment name.
func configurationForEnvironment(env: String) -> Configuration.Type? {
    return configEnvironments[env] // defined in ConfigEnvironments.swift
}