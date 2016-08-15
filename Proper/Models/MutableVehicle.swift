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
import Argo

class MutableVehicle: MutableModel, Comparable {
    typealias FromModel = Vehicle

    // MARK: Internal Properties
    internal let connection: ConnectionType
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Vehicle Support
    var identifier: FromModel.Identifier { return self.name }
    var topic: String { return Vehicle.topicFor(self.identifier) }

    // MARK: Vehicle Attributes
    let name: FromModel.Identifier
    var code: MutableProperty<Int?> = .init(nil)
    var position: MutableProperty<Point?> = .init(nil)
    var capacity: MutableProperty<Int?> = .init(nil)
    var onboard: MutableProperty<Int?> = .init(nil)
    var saturation: MutableProperty<Double?> = .init(nil)
    var lastStation: MutableProperty<MutableStation?> = .init(nil)
    var nextStation: MutableProperty<MutableStation?> = .init(nil)
    var route: MutableProperty<MutableRoute?> = .init(nil)
    var scheduleDelta: MutableProperty<Double?> = .init(nil)
    var heading: MutableProperty<Double?> = .init(nil)
    var speed: MutableProperty<Double?> = .init(nil)

    // MARK: Signal Producer
    lazy var producer: SignalProducer<TopicEvent, PSError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic])
        let future = self.connection.subscribe(self.topic)
        return SignalProducer<SignalProducer<TopicEvent, PSError>, PSError>(values: [now, future])
            .flatten(.Merge)
            .logEvents(identifier: "MutableVehicle.producer", logger: logSignalEvent)
            .attempt { event in
                if let error = event.error {
                    return .Failure(PSError(code: .decodeFailure, associated: error))
                }

                switch event {
                case .Vehicle(.update(let vehicle, _)):
                    do {
                        try self.apply(vehicle.value!)
                    } catch {
                        return .Failure(error as? PSError ?? PSError(code: .mutableModelFailedApply))
                    }
                default:
                    self.delegate.mutableModel(self, receivedTopicEvent: event)
                }
                return .Success()
            }
    }()

    // MARK: Functions
    required init(from vehicle: Vehicle, delegate: MutableModelDelegate, connection: ConnectionType) {
        self.name = vehicle.name
        self.delegate = delegate
        self.connection = connection
        try! apply(vehicle)
    }

    func apply(vehicle: Vehicle) throws {
        if vehicle.identifier != self.identifier {
            throw PSError(code: .mutableModelFailedApply)
        }

        self.code <- vehicle.code
        self.position <- vehicle.position
        self.capacity <- vehicle.capacity
        self.onboard <- vehicle.onboard
        self.saturation <- vehicle.saturation
        self.scheduleDelta <- vehicle.scheduleDelta
        self.heading <- vehicle.heading
        self.speed <- vehicle.speed

        // Currently we don't have a convenience function for 1-to-1 mutable model applies. Instead...
        if let lastStation = vehicle.lastStation {
            if let mutable = self.lastStation.value {
                try mutable.apply(lastStation)
            } else {
                self.lastStation.value = attachMutable(from: lastStation) as MutableStation
            }
        }
        if let nextStation = vehicle.nextStation {
            if let mutable = self.nextStation.value {
                try mutable.apply(nextStation)
            } else {
                self.nextStation.value = attachMutable(from: nextStation) as MutableStation
            }
        }
        if let route = vehicle.route {
            if let mutable = self.route.value {
                try mutable.apply(route)
            } else {
                self.route.value = attachMutable(from: route) as MutableRoute
            }
        }
    }
}

func < (a: MutableVehicle, b: MutableVehicle) -> Bool {
    return a.name < b.name
}
