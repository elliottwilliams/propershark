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
        case update(object: Decoded<Proper.Vehicle>, originator: String)
        case activate(object: Decoded<Proper.Vehicle>, originator: String)
        case deactivate(object: Decoded<Proper.Vehicle>, originator: String)
    }
    
    case Station(StationEvent)
    enum StationEvent {
        case update(object: Decoded<Proper.Station>, originator: String)
        case activate(object: Decoded<Proper.Station>, originator: String)
        case deactivate(object: Decoded<Proper.Station>, originator: String)
        
        case depart(vehicle: Decoded<Proper.Vehicle>, originator: String)
        case arrive(vehicle: Decoded<Proper.Vehicle>, originator: String)
        case approach(vehicle: Decoded<Proper.Vehicle>, distanceInStops: Int, originator: String)
    }
    
    case Route(RouteEvent)
    enum RouteEvent {
        case update(object: Decoded<Proper.Route>, originator: String)
        case activate(object: Decoded<Proper.Route>, originator: String)
        case deactivate(object: Decoded<Proper.Route>, originator: String)
        
        case vehicleUpdate(vehicle: Decoded<Proper.Vehicle>, originator: String)
    }

    case Agency(AgencyEvent)
    enum AgencyEvent {
        case vehicles([AnyObject])
        case stations([AnyObject])
        case routes([AnyObject])
    }

    case Meta(MetaEvent)
    enum MetaEvent {
        case unknownLastEvent(WampArgs, WampKwargs)
    }

    /// Get any underlying DecodeError from the event.
    var error: DecodeError? {
        // TODO: In Swift 3, case statements with multiple patterns can contain variables, so the number of cases here can
        // be dramatically reduced (SE-0043).
        switch self {
        case let .Vehicle(.update(decoded, _)):
            return decoded.error
        case let .Vehicle(.activate(decoded, _)):
            return decoded.error
        case let .Vehicle(.deactivate(decoded, _)):
            return decoded.error
        case let .Station(.update(decoded, _)):
            return decoded.error
        case let .Station(.activate(decoded, _)):
            return decoded.error
        case let .Station(.depart(decoded, _)):
            return decoded.error
        case let .Station(.arrive(decoded, _)):
            return decoded.error
        case let .Station(.approach(decoded, _, _)):
            return decoded.error
        case let .Route(.update(decoded, _)):
            return decoded.error
        case let .Route(.activate(decoded, _)):
            return decoded.error
        case let .Route(.deactivate(decoded, _)):
            return decoded.error
        case let .Route(.vehicleUpdate(decoded, _)):
            return decoded.error
        default:
            return nil
        }
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
            case "vehicles.":   return .Vehicle(.update(object: decode(object), originator: originator))
            case "stations.":   return .Station(.update(object: decode(object), originator: originator))
            case "routes.":     return .Route(.update(object: decode(object), originator: originator))
            default:            return nil
            }
        case (_, "activate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.activate(object: decode(object), originator: originator))
            case "stations.":   return .Station(.activate(object: decode(object), originator: originator))
            case "routes.":     return .Route(.activate(object: decode(object), originator: originator))
            default:            return nil
            }
        case (_, "deactivate"):
            switch topic.hasPrefix {
            case "vehicles.":   return .Vehicle(.deactivate(object: decode(object), originator: originator))
            case "stations.":   return .Station(.deactivate(object: decode(object), originator: originator))
            case "routes.":     return .Route(.deactivate(object: decode(object), originator: originator))
            default:            return nil
            }
            
        case ("stations.", "depart"):
            return .Station(.depart(vehicle: decode(object), originator: originator))
        case ("stations.", "arrive"):
            return .Station(.arrive(vehicle: decode(object), originator: originator))
        case ("stations.", "approach"):
            guard let distance = args[1] as? Int else { return nil }
            return .Station(.approach(vehicle: decode(object), distanceInStops: distance, originator: originator))
        
        case ("routes.", "vehicle_update"):
            return .Route(.vehicleUpdate(vehicle: decode(object), originator: originator))
       
        default:
            return nil
        }
    }

    static func parseFromRPC(topic: String, _ args: WampArgs, _ kwargs: WampKwargs, _ event: MDWampResult) -> TopicEvent? {
        // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
        // check them manually.
        return parseFromRPC(topic,
                            request: (args: args, kwargs: kwargs),
                            response: (
                                args: event.arguments != nil ? event.arguments : [],
                                kwargs: event.argumentsKw != nil ? event.argumentsKw : [:]
                            ))
    }

    static func parseFromRPC(topic: String, request: (args: WampArgs, kwargs: WampKwargs),
                             response: (args: WampArgs, kwargs: WampKwargs)) -> TopicEvent?
    {
        switch topic {
        case "agency.vehicles":
            guard let list = response.args as? [[String: AnyObject]],
                let vehicles = list.first?.values
                else { return nil }
            return .Agency(.vehicles(Array(vehicles)))
        case "agency.stations":
            guard let list = response.args as? [[String: AnyObject]],
                let stations = list.first?.values
                else { return nil }
            return .Agency(.stations(Array(stations)))
        case "agency.routes":
            guard let list = response.args as? [[String: AnyObject]],
                let routes = list.first?.values
                else { return nil }
            return .Agency(.routes(Array(routes)))
        case "meta.last_event":
            guard let metaPayload = response.args[safe: 0] as? [AnyObject],
                let metaArgs = metaPayload[safe: 0] as? WampArgs,
                let metaKwargs = metaPayload[safe: 1] as? WampKwargs
                else { return nil }

            // If we can determine the topic name sent to meta.last_event, parse the reponse as if it came from that
            // topic directly. Otherwise, return a generic meta event.
            if let metaTopic = request.args[safe: 0] as? String {
                return parseFromTopic(metaTopic, args: metaArgs, kwargs: metaKwargs)
            } else {
                return .Meta(.unknownLastEvent(metaArgs, metaKwargs))
            }
        default:
            return nil
        }
    }
}
