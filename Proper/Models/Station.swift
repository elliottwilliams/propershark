//
//  Station.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Station: Model {
    typealias Identifier = String
    
    let code: String?
    let name: String
    let stop_code: Identifier
    let description: String?
    let position: Point?
    
    static var namespace: String { return "stations" }
    var identifier: Identifier { return self.stop_code }
}

extension Station: Decodable {
    static func decode(json: JSON) -> Decoded<Station> {
        return curry(Station.init)
            <^> json <|? "code"
            <*> json <| "name"
            <*> json <| "stop_code"
            <*> json <|? "description"
            <*> .optional(Point.decode(json))
    }
}

