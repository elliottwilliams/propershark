//
//  Station.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct Station: Base {
    let code: String
    let name: String
    let stop_code: String
    let description: String
    let position: Point
    
    static var namespace: String {  "stations" }
    var identifier: String { return self.stop_code }
}

extension Station: Decodable {
    static func decode(json: JSON) -> Decoded<Station> {
        return curry(Station.init)
            <^> json <| "code"
            <*> json <| "name"
            <*> json <| "stop_code"
            <*> json <| "description"
            <*> Point.decode(json)
    }
}