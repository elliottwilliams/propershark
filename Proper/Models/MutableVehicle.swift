//
//  MutableVehicle.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Curry
import Result

struct MutableVehicle: MutableModel {
    typealias FromModel = Vehicle
    let name: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.name }
    var topic: String { return Vehicle.topicFor(self.identifier) }

    let code: MutableProperty<Int>
    let position: MutableProperty<Point>
    let capacity: MutableProperty<Int>
    let onboard: MutableProperty<Int>
    let saturation: MutableProperty<Double>
    let lastStation: MutableProperty<Station>
    let nextStation: MutableProperty<Station>
    let route: MutableProperty<Route>
    let scheduleDelta: MutableProperty<Double>
    let heading: MutableProperty<Double>
    let speed: MutableProperty<Double>

    init(from vehicle: Vehicle) {
        self.name = vehicle.name

        self.code = .init(vehicle.code)
        self.position = .init(vehicle.position)
        self.capacity = .init(vehicle.capacity)
        self.onboard = .init(vehicle.onboard)
        self.saturation = .init(vehicle.saturation)
        self.lastStation = .init(vehicle.lastStation)
        self.nextStation = .init(vehicle.nextStation)
        self.route = .init(vehicle.route)
        self.scheduleDelta = .init(vehicle.scheduleDelta)
        self.heading = .init(vehicle.heading)
        self.speed = .init(vehicle.speed)
    }

    func apply(vehicle: Vehicle) -> Result<(), PSError> {
        if vehicle.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }

        self.code <- vehicle.code
        self.position <- vehicle.position
        self.capacity <- vehicle.capacity
        self.onboard <- vehicle.onboard
        self.saturation <- vehicle.saturation
        self.lastStation <- vehicle.lastStation
        self.nextStation <- vehicle.nextStation
        self.route <- vehicle.route
        self.scheduleDelta <- vehicle.scheduleDelta
        self.heading <- vehicle.heading
        self.speed <- vehicle.speed

        return .Success()
    }
}
