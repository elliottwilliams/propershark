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
    
    static func parse(event: MDWampEvent) -> TopicEvent? {
        return parse(topic: event.topic, args: event.arguments, kwargs: event.argumentsKw)
    }
    
    static func parse(topic topicPrefix: PrefixMatcher, args: [AnyObject], kwargs: [NSObject:AnyObject]) -> TopicEvent? {
        guard let eventName = kwargs["event"] as? String,
            let originator = kwargs["originator"] as? String,
            let object = args[0] as? NSData,
            let json: AnyObject = try? NSJSONSerialization.JSONObjectWithData(object, options: [])
            else { return nil }
        
        let baseValues: EventDefaults = (originator: originator, event: eventName)
        
        switch (topicPrefix, eventName) {
            
        // The base events that all topics emit are handled as one case each, for brevity.
        case (_, "update"):
            switch topicPrefix {
            case "vehicles.":   return .Vehicle(.update(object: json, baseValues))
            case "stations.":   return .Station(.update(object: json, baseValues))
            case "routes.":     return .Route(.update(object: json, baseValues))
            default:            return nil
            }
        case (_, "activate"):
            switch topicPrefix {
            case "vehicles.":   return .Vehicle(.activate(object: json, baseValues))
            case "stations.":   return .Station(.activate(object: json, baseValues))
            case "routes.":     return .Route(.activate(object: json, baseValues))
            default:            return nil
            }
        case (_, "deactivate"):
            switch topicPrefix {
            case "vehicles.":   return .Vehicle(.deactivate(object: json, baseValues))
            case "stations.":   return .Station(.deactivate(object: json, baseValues))
            case "routes.":     return .Route(.deactivate(object: json, baseValues))
            default:            return nil
            }
            
        case ("stations.", "depart"):
            return .Station(.depart(vehicle: json, baseValues))
        case ("stations.", "arrive"):
            return .Station(.arrive(vehicle: json, baseValues))
        case ("stations.", "approach"):
            guard let distance = args[1] as? Int else { return nil }
            return .Station(.approach(vehicle: json, distanceInStops: distance, baseValues))
        
        case ("routes.", "vehicle_update"):
            return .Route(.vehicleUpdate(vehicle: json, baseValues))
       
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
