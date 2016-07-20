//
//  MutableRoute.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result

struct MutableRoute: MutableModel {
    typealias FromModel = Route

    let code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.code }
    var topic: String { return FromModel.topicFor(self.identifier) }

    let name: MutableProperty<String>
    let shortName: MutableProperty<String>
    let description: MutableProperty<String>
    let color: MutableProperty<UIColor>
    let path:  MutableProperty<[Point]>
    let stations: MutableProperty<[String]>

    init(from route: Route) {
        self.code = route.code
        self.name = .init(route.name)
        self.shortName = .init(route.shortName)
        self.description = .init(route.description)
        self.color = .init(route.color)
        self.path = .init(route.path)
        self.stations = .init(route.stations)
    }

    func apply(route: Route) -> Result<(), PSError> {
        if route.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }

        self.name <- route.name
        self.shortName <- route.shortName
        self.description <- route.description
        self.color <- route.color
        self.path <- route.path

        return .Success()
    }
}

func ==(a: [Point], b: [Point]) -> Bool {
    return true
}