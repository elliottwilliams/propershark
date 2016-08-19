//
//  CanonicalRoute.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

/// Model computation that generates a unique, ordered list of routes, given a route itinerary.
struct CanonicalRoute<StationType: Equatable> {
    typealias RouteStopType = RouteStop<StationType>
    let stations: [RouteStopType]

    init(from itinerary: [StationType]) {
        stations = CanonicalRoute.fromItinerary(itinerary)
    }

    /// Reduce an itinerary down to an list of unique constant and conditional stations.
    static func fromItinerary(itinerary: [StationType]) -> [RouteStopType] {
        // Remove adjacent repeats in the itinerary.
        let normalized = normalize(itinerary)
        let reduced = normalized.reduce((route: [RouteStopType](), idx: 0, foundRepeat: false)) { tt, station in
            var (route, i, foundRepeat) = tt

            // Phase 1: Walk the itinerary until a repeat station is found.
            if !foundRepeat {
                if let j = indexOf(station, on: route) {
                    // The repeat might not have been the first item in the itinerary. Mark any stations that came before
                    // this first repeat as conditional.
                    route = conditionals(on: route, from: 0, to: j)
                    // We found the first repeat, so we can proceed to Phase 2 in the next iteration, starting with the
                    // station indexed after this one.
                    return (route, j+1, true)
                } else {
                    // We've never seen this station before, so add it to the condensed route. If it's actually a
                    // conditional stop, we'll figure that out in Phase 2.
                    route.append(.constant(station))
                    return (route, i+1, false)
                }
            }

            // Phase 2: Follow the loop built in phase 1, detecting conditional stations along the way.
            // Wrap around the route index if necessary---the stop after the last stop in the canonical route is the
            // first.
            let ri = i == route.count ? 0 : i
            if route[ri].station != station {
                // If the current station from the itinerary doesn't map the station in its place on the loop, determine
                // how to resolve:
                if let j = indexOf(station, on: route) {
                    // If this station occurs in the route but wasn't expected here, that stations between it and the
                    // expected station are conditional. Mark them as such, and continue reducing from the position in
                    // the route after this station was found.
                    route = conditionals(on: route, from: ri, to: j)
                    return (route, j+1, true)
                } else {
                    // This station must be a conditional, because it isn't on the route even though we've made a
                    // complete loop. Insert it and continue reducing with the same expected station, which has now
                    // moved up an index.
                    route.insert(.conditional(station), atIndex: i)
                    return (route, i+1, true)
                }
            } else {
                // This station matched its expected station, and no changes to the route need to be made.
                return (route, ri+1, true)
            }
        }
        
        return reduced.route
    }

    /// Apply cleaning and normalization steps to an itinerary to prepare it for reduction.
    private static func normalize(itinerary: [StationType]) -> [StationType] {
        // Remove adjacent repeats in the itinerary.
        return itinerary.reduce([]) { normalized, station in
            if normalized.last != station {
                return normalized + [station]
            } else {
                return normalized
            }
        }
    }

    /// Replace a given range of stations with conditional stations, and return the entire route.
    private static func conditionals(on route: [RouteStopType], from: Int, to: Int) -> [RouteStopType] {
        // If from > to, mark conditionals around the end of the route, back to the beginning.
        let ranges: [Range<Int>]
        if from > to {
            ranges = [0..<to, from..<route.count]
        } else {
            ranges = [from..<to]
        }

        // For each range, return the route with that range of stations marked conditional.
        return ranges.reduce(route) { route, range in
            var route = route
            let replacement = route[range].map { RouteStopType.conditional($0.station) }
            route.replaceRange(range, with: replacement)
            return route
        }
    }

    /// Look up the index of a station on the condensed route.
    private static func indexOf(station: StationType, on route: [RouteStopType]) -> Int? {
        return route.lazy.map { $0.station }.indexOf(station)
    }
}