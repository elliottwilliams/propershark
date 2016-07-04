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
        case lastEvent([AnyObject])
    }
    
    static func parseFromTopic(topic: String, event: MDWampResult) -> RPCResult? {
        return parseFromTopic(topic, args: event.arguments, kwargs: event.argumentsKw)
    }
    
    static func parseFromTopic(topic: String, args: [AnyObject], kwargs: [NSObject:AnyObject]) -> RPCResult? {
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