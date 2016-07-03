//
//  Point.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Point {
    let lat: Double
    let long: Double
    
    init(list: [Double]) {
        self.lat = list[0]
        self.long = list[1]
    }
    
    init(lat: Double, long: Double) {
        self.lat = lat
        self.long = long
    }
}

extension Point: Decodable {
    static func decode(json: JSON) -> Decoded<Point> {
        switch json {
        case .Array(_):
            return curry(Point.init(list:))
                <^> decodeArray(json)
            
        case .Object(_):
            return curry(Point.init(lat:long:))
                <^> json <| "latitude"
                <*> json <| "longtiude"
        default:
            return .Failure(.TypeMismatch(expected: "array of coordinates or dictionary", actual: "something else"))
        }
    }
}

func foo() {
    let curried = curry(Point.init(list:))
}