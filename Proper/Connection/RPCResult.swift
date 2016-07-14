//
//  RPCResult.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import MDWamp

enum RPCResult {
    case Agency(AgencyEvent)
    enum AgencyEvent {
        case vehicles([AnyObject])
        case stations([AnyObject])
        case routes([AnyObject])
    }
    
    case Meta(MetaEvent)
    enum MetaEvent {
        case lastEvent(WampArgs)
    }
    
    static func parseFromTopic(topic: String, event: MDWampResult) -> RPCResult? {
        // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
        // check them manually.
        return parseFromTopic(topic,
                              args: event.arguments != nil ? event.arguments : [],
                              kwargs: event.argumentsKw != nil ? event.argumentsKw : [:])
    }
    
    static func parseFromTopic(topic: String, args: WampArgs, kwargs: WampKwargs) -> RPCResult? {
        switch topic {
        case "agency.vehicles":
            guard let list = args as? [[AnyObject]],
                let vehicles = list.first
                else { return nil }
            return .Agency(.vehicles(vehicles))
        case "agency.stations":
            guard let list = args as? [[AnyObject]],
                let stations = list.first
                else { return nil }
            return .Agency(.stations(stations))
        case "agency.routes":
            guard let list = args as? [[AnyObject]],
                let routes = list.first
                else { return nil }
            return .Agency(.routes(routes))
        case "meta.last_event":
            return .Meta(.lastEvent(args))
        default:
            return nil
        }
    }
}
