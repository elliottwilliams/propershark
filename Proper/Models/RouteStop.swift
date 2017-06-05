//
//  RouteStop.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

enum RouteStop<StationType: Equatable>: Equatable {
  case constant(StationType)
  case conditional(StationType)
  var station: StationType {
    switch self {
    case .constant(let station):
      return station
    case .conditional(let station):
      return station
    }
  }
}

func ==<S> (a: RouteStop<S>, b: RouteStop<S>) -> Bool {
  switch (a, b) {
  case (.constant(let stationA), .constant(let stationB)):
    return stationA == stationB
  case (.conditional(let stationA), .conditional(let stationB)):
    return stationA == stationB
  default:
    return false
  }
}
