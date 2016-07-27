//
//  Route.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Route: Model {
    typealias Identifier = String
    
    let code: Identifier
    let name: String?
    let shortName: String?
    let description: String?
    let color: UIColor?
    let path: [Point]?
    
    // Associated objects
    let stations: [Station]?
    
    static var namespace: String { return "routes" }
    static var fullyQualified: String { return "Shark::Route" }
    var identifier: Identifier { return self.code }
    var topic: String { return Route.topicFor(self.identifier) }
}

extension Route: Decodable {
    static func decode(json: JSON) -> Decoded<Route> {
        return curry(Route.init)
            <^> json <| "code"
            <*> json <|? "name"
            <*> json <|? "short_name"
            <*> json <|? "description"
            <*> json <|? "color"
            <*> json <||? "path"
            <*> json <||? "stations"
    }
}