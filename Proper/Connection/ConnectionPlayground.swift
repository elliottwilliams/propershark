//
//  DataStore.swift
//  Proper
//
//  Created by Elliott Williams on 6/18/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Argo
import Curry


protocol ModelBase {
    static var namespace: String { get }
    var identifier: String { get }
    
    func topicFor() -> String
    static func topicFor(identifier: String) -> String
}

extension ModelBase {
    func topicFor() -> String {
        return Self.topicFor(self.identifier)
    }
    static func topicFor(identifier: String) -> String {
        return "\(Self.namespace).\(identifier)"
    }
}


struct ModelRoute: ModelBase {
    let code: String
    let name: String
    let short_name: String
    let description: String
    let color: String
    let path: [Point]
    let stations: [String]

    static var namespace: String { return "routes" }
    var identifier: String { return self.code }
}

extension ModelRoute: Decodable {
    static func decode(json: JSON) -> Decoded<ModelRoute> {
        return curry(ModelRoute.init)
            <^> json <| "code"
            <*> json <| "name"
            <*> json <| "short_name"
            <*> json <| "description"
            <*> json <| "color"
            <*> json <|| "point"
            <*> json <|| "stations"
    }
}

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
        return curry(Point.init) <^> decodeArray(json)
    }
}