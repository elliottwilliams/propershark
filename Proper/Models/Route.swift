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

    // Attributes
    let shortName: String
    let code: Int?
    let name: String?
    let description: String?
    let color: UIColor?
    let path: [Point]?
    
    // Associated objects
    let stations: [Station]?
    let vehicles: [Vehicle]?

    let itinerary: [Station]?

    static var namespace: String { return "routes" }
    static var fullyQualified: String { return "Shark::Route" }
    var identifier: Identifier { return self.shortName }
    var topic: String { return Route.topicFor(self.identifier) }

    init(shortName: String, code: Int? = nil, name: String? = nil, description: String? = nil, color: UIColor? = nil,
         path: [Point]? = nil, stations: [Station]? = nil, vehicles: [Vehicle]? = nil, itinerary: [Station]? = nil)
    {
        self.shortName = shortName
        self.code = code
        self.name = name
        self.description = description
        self.color = color
        self.path = path
        self.stations = stations
        self.vehicles = vehicles
        self.itinerary = itinerary
    }

    init(id shortName: String) throws {
        self.init(shortName: shortName)
    }

    static func validate(route: Route) throws {
        // A defined itinerary necessarily implies defined stations.
        guard (route.itinerary != nil && route.stations != nil) ||
            (route.itinerary == nil && route.stations == nil) else {
                throw PSError(code: .modelStateInconsistency, associated: "itinerary is non-nil but associated stations nil")
        }

        // An itinerary must be a subset of associated stations.
        if let itinerary = route.itinerary, let stations = route.stations {
            let ids: Set<Station.Identifier> = itinerary.reduce(Set()) { set, station in set.union([station.identifier]) }
            guard ids.elementsEqual(stations.map { $0.identifier }) else {
                throw PSError(code: .modelStateInconsistency, associated: "route itinerary is not set equivalent with associated stations")
            }
        }
    }
}
extension Route: Decodable {
    static func decode(json: JSON) -> Decoded<Route> {
        switch json {
        case .String(let id):
            let shortName = Route.unqualify(namespaced: id)
            return .attempt(try pure(Route(id: shortName)))
        default:
            let c = curry(Route.init)
                <^> (json <| "short_name").or(Route.decodeNamespacedIdentifier(json))
                <*> json <|? "code"
                <*> json <|? "name"
                <*> json <|? "description"
                <*> json <|? "color"
                <*> json <||? "path"
                <*> json <||? ["associated_objects", Station.fullyQualified]
                <*> json <||? ["associated_objects", Vehicle.fullyQualified]
                <*> json <||? "itinerary"
        }
    }
}