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
  case vehicle(VehicleEvent)
  enum VehicleEvent {
    case update(object: Decoded<Proper.Vehicle>, originator: String)
    case activate(object: Decoded<Proper.Vehicle>, originator: String)
    case deactivate(object: Decoded<Proper.Vehicle>, originator: String)
  }

  case station(StationEvent)
  enum StationEvent {
    case update(object: Decoded<Proper.Station>, originator: String)
    case activate(object: Decoded<Proper.Station>, originator: String)
    case deactivate(object: Decoded<Proper.Station>, originator: String)

    case depart(vehicle: Decoded<Proper.Vehicle>, originator: String)
    case arrive(vehicle: Decoded<Proper.Vehicle>, originator: String)
    case approach(vehicle: Decoded<Proper.Vehicle>, distanceInStops: Int, originator: String)
  }

  case route(RouteEvent)
  enum RouteEvent {
    case update(object: Decoded<Proper.Route>, originator: String)
    case activate(object: Decoded<Proper.Route>, originator: String)
    case deactivate(object: Decoded<Proper.Route>, originator: String)

    case vehicleUpdate(vehicle: Decoded<Proper.Vehicle>, originator: String)
  }

  case agency(AgencyEvent)
  enum AgencyEvent {
    case vehicles([AnyObject])
    case stations([AnyObject])
    case routes([AnyObject])
  }

  case meta(MetaEvent)
  enum MetaEvent {
    case unknownLastEvent(WampArgs, WampKwargs)
  }

  case timetable(TimetableMessage)
  enum TimetableMessage {
    case arrival(Decoded<Proper.Timetable.Response>)
    case arrivals(Decoded<[Proper.Timetable.Response]>)
  }

  /// Get any underlying DecodeError from the event.
  var error: DecodeError? {
    // TODO: In Swift 3, case statements with multiple patterns can contain variables, so the number of cases here can
    // be dramatically reduced (SE-0043).
    switch self {
    case let .vehicle(.update(decoded, _)): 	    return decoded.error
    case let .vehicle(.activate(decoded, _)): 	    return decoded.error
    case let .vehicle(.deactivate(decoded, _)): 	return decoded.error
    case let .station(.update(decoded, _)): 	    return decoded.error
    case let .station(.activate(decoded, _)): 	    return decoded.error
    case let .station(.deactivate(decoded, _)):     return decoded.error
    case let .station(.depart(decoded, _)): 	    return decoded.error
    case let .station(.arrive(decoded, _)): 	    return decoded.error
    case let .station(.approach(decoded, _, _)): 	return decoded.error
    case let .route(.update(decoded, _)): 	        return decoded.error
    case let .route(.activate(decoded, _)): 	    return decoded.error
    case let .route(.deactivate(decoded, _)): 	    return decoded.error
    case let .route(.vehicleUpdate(decoded, _)): 	return decoded.error
    case let .timetable(.arrival(decoded)):         return decoded.error
    case let .timetable(.arrivals(decoded)):        return decoded.error
    default:                                        return nil
    }
  }

  var description: String {
    // TODO: In Swift 3, case statements with multiple patterns can contain variables, so the number of cases here can
    // be dramatically reduced (SE-0043).
    switch self {
    case let .vehicle(.update(_, originator)):
      return "vehicle.update <- \(originator)"
    case let .vehicle(.activate(_, originator)):
      return "vehicle.activate <- \(originator)"
    case let .vehicle(.deactivate(_, originator)):
      return "vehicle.deactivate <- \(originator)"
    case let .station(.update(_, originator)):
      return "station.update <- \(originator)"
    case let .station(.activate(_, originator)):
      return "station.activate <- \(originator)"
    case let .station(.deactivate(_, originator)):
      return "station.deactivate <- \(originator)"
    case let .station(.depart(_, originator)):
      return "station.depart <- \(originator)"
    case let .station(.arrive(_, originator)):
      return "station.arrive <- \(originator)"
    case let .station(.approach(_, originator, _)):
      return "station.approach <- \(originator)"
    case let .route(.update(_, originator)):
      return "route.update <- \(originator)"
    case let .route(.activate(_, originator)):
      return "route.activate <- \(originator)"
    case let .route(.deactivate(_, originator)):
      return "route.deactivate <- \(originator)"
    case let .route(.vehicleUpdate(_, originator)):
      return "route.vehicleUpdate <- \(originator)"
    case let .agency(.vehicles(list)):
      return "agency.vehicles (\(list.count) vehicles)"
    case let .agency(.stations(list)):
      return "agency.stations (\(list.count) stations)"
    case let .agency(.routes(list)):
      return "agency.routes (\(list.count) routes)"
    case .meta(.unknownLastEvent(_, _)):
      return "meta.unknownLastEvent"
    case let .timetable(.arrival(arrival)):
      return "timetable.arrival (\(String(describing: arrival.value)))"
    case let .timetable(.arrivals(arrivals)):
      return "timetable.arrivals (\(String(describing: arrivals.value)))"
    }
  }

  var originator: String? {
    switch self {
    case let .vehicle(.update(_, originator)): 	    return originator
    case let .vehicle(.activate(_, originator)): 	return originator
    case let .vehicle(.deactivate(_, originator)): 	return originator
    case let .station(.update(_, originator)): 	    return originator
    case let .station(.activate(_, originator)): 	return originator
    case let .station(.depart(_, originator)): 	    return originator
    case let .station(.arrive(_, originator)): 	    return originator
    case let .station(.approach(_, _, originator)): return originator
    case let .route(.update(_, originator)): 	    return originator
    case let .route(.activate(_, originator)): 	    return originator
    case let .route(.deactivate(_, originator)): 	return originator
    case let .route(.vehicleUpdate(_, originator)): return originator
    default:                                        return nil
    }
  }

  static func parse(from topic: String, event: MDWampEvent) -> TopicEvent? {
    // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
    // check them manually.
    return parse(from: topic,
                 args: event.arguments ?? [],
                 kwargs: event.argumentsKw ?? [:])
  }

  static func parse(from topic: String, args: WampArgs, kwargs: WampKwargs) -> TopicEvent? {
    guard let eventName = kwargs["event"] as? String,
      let originator = kwargs["originator"] as? String,
      let object = args[safe: 0]
      else { return nil }

    switch (topic.hasPrefix, eventName) {

    // The base events that all topics emit are handled as one case each, for brevity.
    case (_, "update"):
      switch topic.hasPrefix {
      case "vehicles.":   return .vehicle(.update(object: decode(object), originator: originator))
      case "stations.":   return .station(.update(object: decode(object), originator: originator))
      case "routes.":     return .route(.update(object: decode(object), originator: originator))
      default:            return nil
      }
    case (_, "activate"):
      switch topic.hasPrefix {
      case "vehicles.":   return .vehicle(.activate(object: decode(object), originator: originator))
      case "stations.":   return .station(.activate(object: decode(object), originator: originator))
      case "routes.":     return .route(.activate(object: decode(object), originator: originator))
      default:            return nil
      }
    case (_, "deactivate"):
      switch topic.hasPrefix {
      case "vehicles.":   return .vehicle(.deactivate(object: decode(object), originator: originator))
      case "stations.":   return .station(.deactivate(object: decode(object), originator: originator))
      case "routes.":     return .route(.deactivate(object: decode(object), originator: originator))
      default:            return nil
      }

    case ("stations.", "depart"):
      return .station(.depart(vehicle: decode(object), originator: originator))
    case ("stations.", "arrive"):
      return .station(.arrive(vehicle: decode(object), originator: originator))
    case ("stations.", "approach"):
      guard let distance = args[1] as? Int else { return nil }
      return .station(.approach(vehicle: decode(object), distanceInStops: distance, originator: originator))

    case ("routes.", "vehicle_update"):
      return .route(.vehicleUpdate(vehicle: decode(object), originator: originator))

    default:
      return nil
    }
  }

  static func parse(fromRPC proc: String, _ args: WampArgs, _ kwargs: WampKwargs, _ event: MDWampResult) -> TopicEvent? {
    // Arguments and argumentsKw come implicitly unwrapped (from their dirty dirty objc library), so we need to
    // check them manually.
    return parse(fromRPC: proc,
                 request: (args: args, kwargs: kwargs),
                 response: (
                  args: event.arguments != nil ? event.arguments : [],
                  kwargs: event.argumentsKw != nil ? event.argumentsKw : [:]
    ))
  }

  static func parse(fromRPC proc: String, request: (args: WampArgs, kwargs: WampKwargs),
                    response: (args: WampArgs, kwargs: WampKwargs)) -> TopicEvent?
  {
    if Config.current.logging.logJSON {
      NSLog("[TopicEvent.parseFromRPC] \(proc) -> \(response)")
    }

    switch proc {
    case "agency.vehicles":
      guard let list = response.args as? [[String: AnyObject]],
        let vehicles = list.first?.values
        else { return nil }
      return .agency(.vehicles(Array(vehicles)))
    case "agency.stations":
      guard let list = response.args as? [[String: AnyObject]],
        let stations = list.first?.values
        else { return nil }
      return .agency(.stations(Array(stations)))
    case "agency.routes":
      guard let list = response.args as? [[String: AnyObject]],
        let routes = list.first?.values
        else { return nil }
      return .agency(.routes(Array(routes)))
    case "meta.last_event":
      guard let metaPayload = response.args[safe: 0] as? [AnyObject],
        let metaArgs = metaPayload[safe: 0] as? WampArgs,
        let metaKwargs = metaPayload[safe: 1] as? WampKwargs
        else { return nil }

      // If we can determine the topic name sent to meta.last_event, parse the reponse as if it came from that
      // topic directly. Otherwise, return a generic meta event.
      if let metaTopic = request.args[safe: 0] as? String {
        return parse(from: metaTopic, args: metaArgs, kwargs: metaKwargs)
      } else {
        return .meta(.unknownLastEvent(metaArgs, metaKwargs))
      }

    case "timetable.next_visit", "timetable.last_visit",
         "providence.next_visit", "providence.last_visit":
      guard let tuple = response.args[safe: 0]
        else { return nil }
      return .timetable(.arrival(decode(tuple)))

    case "timetable.visits_before", "timetable.visits_after", "timetable.visits_between",
         "providence.visits_before", "providence.visits_after", "providence.visits_between":
      guard let tuples = response.args[safe: 0]
        else { return nil }
      return .timetable(.arrivals(decodeArray(JSON(tuples))))

    default:
      return nil
    }
  }

  static private func parseTimetableTuple(_ args: [[AnyObject]]) -> (eta: Decoded<Date>, etd: Decoded<Date>)? {
    guard let eta = args[safe: 0],
      let etd = args[safe: 1]
      else { return nil }
    return (eta: decode(eta), etd: decode(etd))
  }
}
