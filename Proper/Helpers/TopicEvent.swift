//
//  TopicEvent.swift
//  Proper
//
//  Created by Elliott Williams on 7/1/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MDWamp
import Argo


enum TopicEvent {
    case Vehicle(VehicleEvent)
    enum VehicleEvent {
        case update(object: AnyObject, originator: String)
        case activate(object: AnyObject, originator: String)
        case deactivate(object: AnyObject, originator: String)
    }
    
    case Station(StationEvent)
    enum StationEvent {
        case update(object: AnyObject, originator: String)
        case activate(object: AnyObject, originator: String)
        case deactivate(object: AnyObject, originator: String)
        
        case depart(vehicle: AnyObject, originator: String)
        case arrive(vehicle: AnyObject, originator: String)
        case approach(vehicle: AnyObject, distanceInStops: Int, originator: String)
    }
    
    case Route(RouteEvent)
    enum RouteEvent {
        case update(object: AnyObject, originator: String)
        case activate(object: AnyObject, originator: String)
        case deactivate(object: AnyObject, originator: String)
        
        case vehicleUpdate(vehicle: Proper.Vehicle, originator: String)
    }

    case Agency(AgencyEvent)
    enum AgencyEvent {
        case vehicles([AnyObject])
        case stations([AnyObject])
        case routes([AnyObject])
    }

    case Meta(MetaEvent)
    enum MetaEvent {
        case lastEvent(WampArgs, WampKwargs)
    }
    
    static func parseFromTopic(topic: String, event: MDWampEvent) -> TopicEvent? {
        // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
        // check them manually.
        return parseFromTopic(topic,
            args: event.arguments != nil ?  event.arguments : [],
            kwargs: event.argumentsKw != nil ?  event.argumentsKw : [:])
    }
    
    static func parseFromTopic(topic: String, args: WampArgs, kwargs: WampKwargs) -> TopicEvent? {
        guard let eventName = kwargs["event"] as? String,
            let originator = kwargs["originator"] as? String,
            let object = args[safe: 0]
            else { return nil }
        
        switch (topic.hasPrefix, eventName) {
            
        // The base events that all topics emit are handled as one case each, for brevity.
        case (_, "update"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.update(object: object, originator: originator))
            case "stations.":   return .Station(.update(object: object, originator: originator))
            case "routes.":     return .Route(.update(object: object, originator: originator))
            default:            return nil
            }
        case (_, "activate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.activate(object: object, originator: originator))
            case "stations.":   return .Station(.activate(object: object, originator: originator))
            case "routes.":     return .Route(.activate(object: object, originator: originator))
            default:            return nil
            }
        case (_, "deactivate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.deactivate(object: object, originator: originator))
            case "stations.":   return .Station(.deactivate(object: object, originator: originator))
            case "routes.":     return .Route(.deactivate(object: object, originator: originator))
            default:            return nil
            }
            
        case ("stations.", "depart"):
            return .Station(.depart(vehicle: object, originator: originator))
        case ("stations.", "arrive"):
            return .Station(.arrive(vehicle: object, originator: originator))
        case ("stations.", "approach"):
            guard let distance = args[1] as? Int else { return nil }
            return .Station(.approach(vehicle: object, distanceInStops: distance, originator: originator))
        
        case ("routes.", "vehicle_update"):
            guard let vehicle = decode(object) as Proper.Vehicle? else { return nil }
            return .Route(.vehicleUpdate(vehicle: vehicle, originator: originator))
       
        default:
            return nil
        }
    }

    static func parseFromRPC(topic: String, event: MDWampResult) -> TopicEvent? {
        // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
        // check them manually.
        return parseFromRPC(topic,
                            args: event.arguments != nil ? event.arguments : [],
                            kwargs: event.argumentsKw != nil ? event.argumentsKw : [:])
    }

    static func parseFromRPC(topic: String, args: WampArgs, kwargs: WampKwargs) -> TopicEvent? {
        switch topic {
        case "agency.vehicles":
            guard let list = args as? [[String: AnyObject]],
                let vehicles = list.first?.values
                else { return nil }
            return .Agency(.vehicles(Array(vehicles)))
        case "agency.stations":
            guard let list = args as? [[String: AnyObject]],
                let stations = list.first?.values
                else { return nil }
            return .Agency(.stations(Array(stations)))
        case "agency.routes":
            guard let list = args as? [[String: AnyObject]],
                let routes = list.first?.values
                else { return nil }
            return .Agency(.routes(Array(routes)))
        case "meta.last_event":
            return .Meta(.lastEvent(args, kwargs))
        default:
            return nil
        }
    }
}
