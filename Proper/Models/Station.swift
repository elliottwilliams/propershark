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

    init(stopCode: String, name: String? = nil, description: String? = nil, position: Point? = nil,
         routes: [Route]? = nil, vehicles: [Vehicle]? = nil)
    {
        self.stopCode = stopCode
        self.name = name
        self.description = description
        self.position = position
        self.routes = routes
        self.vehicles = vehicles
    }

    init(id stopCode: String) {
        self.init(stopCode: stopCode)
    }
}

extension Station: Decodable {
    private func validate(station: Station) -> Bool {
        
    }

    static func decode(json: JSON) -> Decoded<Station> {
        switch json {
        case .String(let id):
            let stopCode = Station.unqualify(namespaced: id)
            return pure(Station(id: stopCode))
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
