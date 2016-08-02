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

    // Attributes
    let stop_code: Identifier
    let name: String?
    let description: String?
    let position: Point?

    // Associated objects
    let routes: [Route]?
    let vehicles: [Vehicle]?
    
    static var namespace: String { return "stations" }
    static var fullyQualified: String { return "Shark::Station" }
    var identifier: Identifier { return self.stop_code }
    var topic: String { return Station.topicFor(self.identifier) }
}

extension Station: Decodable {
    static func decode(json: JSON) -> Decoded<Station> {
        return curry(Station.init)
            <^> Station.decodeIdentifier(json).or(json <| "stop_code")
            <*> json <|? "name"
            <*> json <|? "description"
            <*> Point.decode(json)
            <*> json <||? ["associated_objects", Route.fullyQualified]
            <*> json <||? ["associated_objects", Vehicle.fullyQualified]
    }
}

