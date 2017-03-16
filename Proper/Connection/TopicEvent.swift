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


enum TopicEvent: CustomStringConvertible {
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

    case Timetable(TimetableMessage)
    enum TimetableMessage {
        case arrival(Decoded<Arrival>)
        case arrivals(Decoded<[Arrival]>)
    }

    /// Get any underlying DecodeError from the event.
    var error: DecodeError? {
        // TODO: In Swift 3, case statements with multiple patterns can contain variables, so the number of cases here can
        // be dramatically reduced (SE-0043).
        switch self {
        case let .Vehicle(.update(decoded, _)): 	    return decoded.error
        case let .Vehicle(.activate(decoded, _)): 	    return decoded.error
        case let .Vehicle(.deactivate(decoded, _)): 	return decoded.error
        case let .Station(.update(decoded, _)): 	    return decoded.error
        case let .Station(.activate(decoded, _)): 	    return decoded.error
        case let .Station(.deactivate(decoded, _)):     return decoded.error
        case let .Station(.depart(decoded, _)): 	    return decoded.error
        case let .Station(.arrive(decoded, _)): 	    return decoded.error
        case let .Station(.approach(decoded, _, _)): 	return decoded.error
        case let .Route(.update(decoded, _)): 	        return decoded.error
        case let .Route(.activate(decoded, _)): 	    return decoded.error
        case let .Route(.deactivate(decoded, _)): 	    return decoded.error
        case let .Route(.vehicleUpdate(decoded, _)): 	return decoded.error
        case let .Timetable(.arrival(decoded)):         return decoded.error
        case let .Timetable(.arrivals(decoded)):        return decoded.error
        default:                                        return nil
        }
    }

    var description: String {
        // TODO: In Swift 3, case statements with multiple patterns can contain variables, so the number of cases here can
        // be dramatically reduced (SE-0043).
        switch self {
        case let .Vehicle(.update(_, originator)):
            return "vehicle.update <- \(originator)"
        case let .Vehicle(.activate(_, originator)): 	    
            return "vehicle.activate <- \(originator)"
        case let .Vehicle(.deactivate(_, originator)):     
            return "vehicle.deactivate <- \(originator)"
        case let .Station(.update(_, originator)): 	    
            return "station.update <- \(originator)"
        case let .Station(.activate(_, originator)): 	    
            return "station.activate <- \(originator)"
        case let .Station(.deactivate(_, originator)):
            return "station.deactivate <- \(originator)"
        case let .Station(.depart(_, originator)):
            return "station.depart <- \(originator)"
        case let .Station(.arrive(_, originator)): 	    
            return "station.arrive <- \(originator)"
        case let .Station(.approach(_, originator, _)):    
            return "station.approach <- \(originator)"
        case let .Route(.update(_, originator)): 	        
            return "route.update <- \(originator)"
        case let .Route(.activate(_, originator)): 	    
            return "route.activate <- \(originator)"
        case let .Route(.deactivate(_, originator)): 	    
            return "route.deactivate <- \(originator)"
        case let .Route(.vehicleUpdate(_, originator)):    
            return "route.vehicleUpdate <- \(originator)"
        case let .Agency(.vehicles(list)):
            return "agency.vehicles (\(list.count) vehicles)"
        case let .Agency(.stations(list)):
            return "agency.stations (\(list.count) stations)"
        case let .Agency(.routes(list)):
            return "agency.routes (\(list.count) routes)"
        case .Meta(.unknownLastEvent(_, _)):
            return "meta.unknownLastEvent"
        case let .Timetable(.arrival(arrival)):
            return "timetable.arrival (\(arrival.value))"
        case let .Timetable(.arrivals(arrivals)):
            return "timetable.arrivals (\(arrivals.value))"
        }
    }

    var originator: String? {
        switch self {
        case let .Vehicle(.update(_, originator)): 	    return originator
        case let .Vehicle(.activate(_, originator)): 	return originator
        case let .Vehicle(.deactivate(_, originator)): 	return originator
        case let .Station(.update(_, originator)): 	    return originator
        case let .Station(.activate(_, originator)): 	return originator
        case let .Station(.depart(_, originator)): 	    return originator
        case let .Station(.arrive(_, originator)): 	    return originator
        case let .Station(.approach(_, _, originator)): return originator
        case let .Route(.update(_, originator)): 	    return originator
        case let .Route(.activate(_, originator)): 	    return originator
        case let .Route(.deactivate(_, originator)): 	return originator
        case let .Route(.vehicleUpdate(_, originator)): return originator
        default:                                        return nil
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

    static func parseFromRPC(proc: String, _ args: WampArgs, _ kwargs: WampKwargs, _ event: MDWampResult) -> TopicEvent? {
        // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
        // check them manually.
        return parseFromRPC(proc,
                            request: (args: args, kwargs: kwargs),
                            response: (
                                args: event.arguments != nil ? event.arguments : [],
                                kwargs: event.argumentsKw != nil ? event.argumentsKw : [:]
                            ))
    }

    static func parseFromRPC(proc: String, request: (args: WampArgs, kwargs: WampKwargs),
                             response: (args: WampArgs, kwargs: WampKwargs)) -> TopicEvent?
    {
        if Config.logging.logJSON {
            NSLog("[TopicEvent.parseFromRPC] \(proc) -> \(response)")
        }

        switch proc {
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

        case "timetable.next_visit", "timetable.last_visit":
            guard let tuple = response.args[safe: 0]
                else { return nil }
            return .Timetable(.arrival(decode(tuple)))

        case "timetable.visits_before", "timetable.visits_after", "timetable.visits_between":
            guard let tuples = response.args[safe: 0],
                let count = request.args[safe: 3] as? Int where
                tuples.count == count
                else { return nil }
            return .Timetable(.arrivals(decodeArray(JSON(tuples))))

        default:
            return nil
        }
    }

    static private func parseTimetableTuple(args: [[AnyObject]]) -> (eta: Decoded<NSDate>, etd: Decoded<NSDate>)? {
        guard let eta = args[safe: 0] as? AnyObject,
            let etd = args[safe: 1] as? AnyObject
            else { return nil }
        return (eta: decode(eta), etd: decode(etd))
    }
}
