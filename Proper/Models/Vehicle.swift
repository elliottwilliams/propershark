//
//  Vehicle.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Vehicle: Model {
    typealias Identifier = String

    // MARK: Attributes

    /// The (often) humanized name for this vehicle
    let name: String
    
    /// The identifying code for this vehicle
    let code: Int?
    /// The geographic coordinates of this vehicle's current location
    let position: Point?
    
    /// The number of passengers that this vehicle can carry at any given time
    let capacity: Int?
    /// The number of passengers currently onboard this vehicle
    let onboard: Int?
    /// The fullness of the vehicle expressed as a percentage in the range [0-1]
    let saturation: Double?
    
    /// The last stop that this vehicle departed from
    let lastStation: Station?
    /// The next stop that this vehicle will arrive at
    let nextStation: Station?
    
    /// The route that this vehicle is currently traveling on
    let route: Route?
    
    /// The amount of time by which this vehicle currently differs from the 
    /// schedule it is following (determined by `route`), stored as an integral number of seconds
    let scheduleDelta: Double?
    /// The directional heading of this vehicle in the range [0-360)
    let heading: Double?
    /// The speed that the vehicle is currently travelling at
    let speed: Double?

    // MARK: Support Properties
    static var namespace: String { return "vehicles" }
    var identifier: String { return self.name }
    var topic: String { return Vehicle.topicFor(self.identifier) }
    static var fullyQualified: String { return "Shark::Vehicle" }

    init(name: String, code: Int? = nil, position: Point? = nil, capacity: Int? = nil, onboard: Int? = nil,
         saturation: Double? = nil, lastStation: Station? = nil, nextStation: Station? = nil, route: Route? = nil,
         scheduleDelta: Double? = nil, heading: Double? = nil, speed: Double? = nil)
    {
        self.name = name
        self.code = code
        self.position = position
        self.capacity = capacity
        self.onboard = onboard
        self.saturation = saturation
        self.lastStation = lastStation
        self.nextStation = nextStation
        self.route = route
        self.scheduleDelta = scheduleDelta
        self.heading = heading
        self.speed = speed
    }

    init(id name: String) {
        self.init(name: name)
    }
}

extension Vehicle: Decodable {
    static func decode(json: JSON) -> Decoded<Vehicle> {
        switch json {
        case .String(let id):
            let name = Vehicle.unqualify(namespaced: id)
            return pure(Vehicle(id: name))
        default:
            let v = curry(Vehicle.init)
                <^> (json <| "name").or(Vehicle.decodeNamespacedIdentifier(json))
                <*> json <|? "code"
                <*> .optional(Point.decode(json))

            return v
                <*> json <|? "capacity"
                <*> json <|? "onboard"
                <*> json <|? "saturation"
                <*> json <|? "last_station"
                <*> json <|? "next_station"
                <*> json <|? "route"
                <*> json <|? "schedule_delta"
                <*> json <|? "heading"
                <*> json <|? "speed"
        }
    }
}
