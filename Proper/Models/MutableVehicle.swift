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

class MutableVehicle: MutableModel {
    typealias FromModel = Vehicle

    // MARK: Properties
    let name: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.name }
    var topic: String { return Vehicle.topicFor(self.identifier) }
    var delegate: MutableModelDelegate

    let code: MutableProperty<Int?>
    let position: MutableProperty<Point?>
    let capacity: MutableProperty<Int?>
    let onboard: MutableProperty<Int?>
    let saturation: MutableProperty<Double?>
    let lastStation: MutableProperty<Station?>
    let nextStation: MutableProperty<Station?>
    let route: MutableProperty<Route?>
    let scheduleDelta: MutableProperty<Double?>
    let heading: MutableProperty<Double?>
    let speed: MutableProperty<Double?>

    internal let connection: ConnectionType = Connection.sharedInstance
    private static let retryAttempts = 3
    lazy var producer: SignalProducer<Vehicle, NoError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic]).map {
            TopicEvent.parseFromRPC("meta.last_event", event: $0)
        }
        let future = self.connection.subscribe(self.topic).map {
            TopicEvent.parseFromTopic(self.topic, event: $0)
        }
        return SignalProducer<SignalProducer<TopicEvent?, PSError>, PSError>(values: [now, future])
            .flatten(.Merge).unwrapOrFail { PSError(code: .parseFailure) }
            .map { (event: TopicEvent) -> Vehicle? in
                switch event {
                case .Meta(.lastEvent(let args, _)):
                    guard let object = args.first else { return nil }
                    return decode(object)
                case .Vehicle(.update(let object, _)):
                    return decode(object)
                default:
                    return nil
                }
            }
            .unwrapOrFail { PSError(code: .decodeFailure) }
            .retry(MutableVehicle.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Vehicle, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Vehicle, NoError>.empty
        }
    }()

    required init(from vehicle: Vehicle, delegate: MutableModelDelegate) {
        self.name = vehicle.name
        self.delegate = delegate

        // Initialize with current value
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

        // Bind to future values
        self.code <~ self.producer.map { $0.code }
        self.position <~ self.producer.map { $0.position }
        self.capacity <~ self.producer.map { $0.capacity }
        self.onboard <~ self.producer.map { $0.onboard }
        self.saturation <~ self.producer.map { $0.saturation }
        self.lastStation <~ self.producer.map { $0.lastStation }
        self.nextStation <~ self.producer.map { $0.nextStation }
        self.route <~ self.producer.map { $0.route }
        self.scheduleDelta <~ self.producer.map { $0.scheduleDelta }
        self.heading <~ self.producer.map { $0.heading }
        self.speed <~ self.producer.map { $0.speed }
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
