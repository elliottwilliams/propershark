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

    // MARK: Properties
    let name: String?
    let stop_code: Identifier
    let description: String?
    let position: Point?

    // MARK: Associated objects
    let routes: [Route]?
    
    static var namespace: String { return "stations" }
    static var fullyQualified: String { return "Shark::Station" }
    var identifier: Identifier { return self.stop_code }
    var topic: String { return Station.topicFor(self.identifier) }
}

extension Station: Decodable {
    static func decode(json: JSON) -> Decoded<Station> {
        return curry(Station.init)
            <^> json <|? "name"
            <*> json <| "stop_code"
            <*> json <|? "description"
            <*> Point.decode(json)
            <*> json <||? ["associated_objects", Route.fullyQualified]
    }
}

