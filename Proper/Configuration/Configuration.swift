//
//  Configuration.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

protocol ConfigAware {
    var config: Config { get }
}

struct Config {
    static let sharedInstance = Config.init()
    
    let environment = "dev"
    let agency = "citybus"
    let connection = (
        server: NSURL(string: "ws://io:8080/ws")!,
        realm: "realm1"
    )
}