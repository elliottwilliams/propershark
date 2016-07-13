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
    typealias Identifier = Int
    
    let code: Identifier
    let name: String
    let shortName: String
    let description: String
    let color: UIColor
    let path: [Point]
    
    // Expected to change to [Station] in the future (shark#5)
    let stations: [String]
    
    static var namespace: String { return "routes" }
    var identifier: Identifier { return self.code }
}

extension Route: Decodable {
    static func decode(json: JSON) -> Decoded<Route> {
        return curry(Route.init)
            <^> json <| "code"
            <*> json <| "name"
            <*> json <| "short_name"
            <*> json <| "description"
            <*> json <| "color"
            <*> json <|| "path"
            <*> json <|| "stations"
    }
}