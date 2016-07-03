//
//  TopicEvent.swift
//  Proper
//
//  Created by Elliott Williams on 7/1/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MDWamp


// Meta keys sent on every Shark event
typealias EventDefaults = (originator: String, event: String)

enum TopicEvent {
    
    case Vehicle(VehicleEvent)
    enum VehicleEvent {
        case update(object: AnyObject, EventDefaults)
        case activate(object: AnyObject, EventDefaults)
        case deactivate(object: AnyObject, EventDefaults)
    }
    
    case Station(StationEvent)
    enum StationEvent {
        case update(object: AnyObject, EventDefaults)
        case activate(object: AnyObject, EventDefaults)
        case deactivate(object: AnyObject, EventDefaults)
        
        case depart(vehicle: AnyObject, EventDefaults)
        case arrive(vehicle: AnyObject, EventDefaults)
        case approach(vehicle: AnyObject, distanceInStops: Int, EventDefaults)
    }
    
    case Route(RouteEvent)
    enum RouteEvent {
        case update(object: AnyObject, EventDefaults)
        case activate(object: AnyObject, EventDefaults)
        case deactivate(object: AnyObject, EventDefaults)
        
        case vehicleUpdate(vehicle: AnyObject, EventDefaults)
    }
    
    static func parseFromTopic(topic: String, event: MDWampEvent) -> TopicEvent? {
        return parseFromTopic(topic, args: event.arguments, kwargs: event.argumentsKw)
    }
    
    static func parseFromTopic(topic: String, args: [AnyObject], kwargs: [NSObject:AnyObject]) -> TopicEvent? {
        guard let eventName = kwargs["event"] as? String,
            let originator = kwargs["originator"] as? String,
            let object = args[safe: 0]
            else { return nil }
        
        let baseValues: EventDefaults = (originator: originator, event: eventName)
        
        switch (topic.hasPrefix, eventName) {
            
        // The base events that all topics emit are handled as one case each, for brevity.
        case (_, "update"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.update(object: object, baseValues))
            case "stations.":   return .Station(.update(object: object, baseValues))
            case "routes.":     return .Route(.update(object: object, baseValues))
            default:            return nil
            }
        case (_, "activate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.activate(object: object, baseValues))
            case "stations.":   return .Station(.activate(object: object, baseValues))
            case "routes.":     return .Route(.activate(object: object, baseValues))
            default:            return nil
            }
        case (_, "deactivate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.deactivate(object: object, baseValues))
            case "stations.":   return .Station(.deactivate(object: object, baseValues))
            case "routes.":     return .Route(.deactivate(object: object, baseValues))
            default:            return nil
            }
            
        case ("stations.", "depart"):
            return .Station(.depart(vehicle: object, baseValues))
        case ("stations.", "arrive"):
            return .Station(.arrive(vehicle: object, baseValues))
        case ("stations.", "approach"):
            guard let distance = args[1] as? Int else { return nil }
            return .Station(.approach(vehicle: object, distanceInStops: distance, baseValues))
        
        case ("routes.", "vehicle_update"):
            return .Route(.vehicleUpdate(vehicle: object, baseValues))
       
        default:
            return nil
        }
    }

}

enum RPCResult {
    case Agency(AgencyEvent)
    enum AgencyEvent {
        case vehicles([AnyObject])
        case stations([AnyObject])
        case routes([AnyObject])
    }
    
    case Meta(MetaEvent)
    enum MetaEvent {
        case lastEvent([AnyObject])
    }

    static func parse(topic: String, event: MDWampResult) -> RPCResult? {
        return parse(topic, args: event.arguments, kwargs: event.argumentsKw)
    }
    
    static func parse(topic: String, args: [AnyObject], kwargs: [NSObject:AnyObject]) -> RPCResult? {
        switch topic {
        case "agency.vehicles":
            return .Agency(.vehicles(args))
        case "agency.stations":
            return .Agency(.stations(args))
        case "agency.routes":
            return .Agency(.routes(args))
        case "meta.last_event":
            return .Meta(.lastEvent(args))
        default:
            return nil
        }
    }
}
