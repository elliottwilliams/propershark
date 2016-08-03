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
    let stopCode: String
    let name: String?
    let description: String?
    let position: Point?

    // Associated objects
    let routes: [Route]?
    let vehicles: [Vehicle]?
    
    static var namespace: String { return "stations" }
    static var fullyQualified: String { return "Shark::Station" }
    var identifier: Identifier { return self.stopCode }
    var topic: String { return Station.topicFor(self.identifier) }
}

extension Station {
    init(stopCode: String) {
        self.init(stopCode: stopCode, name: nil, description: nil, position: nil, routes: nil,
                  vehicles: nil)
    }
}

extension Station: Decodable {
    static func decode(json: JSON) -> Decoded<Station> {
        switch json {
        case .String(let id):
            let stopCode = Station.unqualify(namespaced: id)
            return pure(Station(stopCode: stopCode))
        default:
            let curried = curry(Station.init)
            return curried
                <^> (json <| "stop_code").or(Station.decodeNamespacedIdentifier(json))
                <*> json <|? "name"
                <*> json <|? "description"
                <*> .optional(Point.decode(json))
                <*> json <||? ["associated_objects", Route.fullyQualified]
                <*> json <||? ["associated_objects", Vehicle.fullyQualified]
        }
    }
}
