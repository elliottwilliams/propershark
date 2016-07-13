//
//  MutableRoute.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa

struct MutableRoute: MutableModel {
    typealias FromModel = Route

    let code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.code }

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

    func apply(route: Route) throws {
        if route.identifier != self.identifier {
            throw PSError(code: .mutableModelFailedApply)
        }

        self.name <- route.name
        self.shortName <- route.shortName
        self.description <- route.description
        self.color <- route.color
        self.path <- route.path
    }
}

func ==(a: [Point], b: [Point]) -> Bool {
    return true
}