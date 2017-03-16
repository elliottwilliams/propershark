//
//  ArrivalMessage.swift
//  Proper
//
//  Created by Elliott Williams on 3/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import Argo
import Curry

struct ArrivalMessage: Decodable {
    let route: Route
    let heading: String?
    let time: ArrivalTime

    static func decode(json: JSON) -> Decoded<ArrivalMessage> {
        return [JSON].decode(json).flatMap({ args in
            guard args.count == 4 else {
                return .Failure(.Custom("Expected an array of size 4"))
            }

            return curry(self.init)
                <^> Route.decode(args[0])
                <*> Optional<String>.decode(args[1])
                <*> ArrivalTime.decode(JSON.Array(Array(args.suffixFrom(2))))
        })
    }
}
