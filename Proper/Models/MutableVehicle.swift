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

    // MARK: Internal Properties
    internal let connection: ConnectionType = Connection.sharedInstance
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Vehicle Support
    internal var source: FromModel
    var identifier: FromModel.Identifier { return self.code }
    var topic: String { return Vehicle.topicFor(self.identifier) }

    // MARK: Vehicle Attributes
    let code: FromModel.Identifier
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name }
    lazy var position: MutableProperty<Point?> = self.lazyProperty { $0.position }
    lazy var capacity: MutableProperty<Int?> = self.lazyProperty { $0.capacity }
    lazy var onboard: MutableProperty<Int?> = self.lazyProperty { $0.onboard }
    lazy var saturation: MutableProperty<Double?> = self.lazyProperty { $0.saturation }
    lazy var lastStation: MutableProperty<Station?> = self.lazyProperty { $0.lastStation }
    lazy var nextStation: MutableProperty<Station?> = self.lazyProperty { $0.nextStation }
    lazy var route: MutableProperty<Route?> = self.lazyProperty { $0.route }
    lazy var scheduleDelta: MutableProperty<Double?> = self.lazyProperty { $0.scheduleDelta }
    lazy var heading: MutableProperty<Double?> = self.lazyProperty { $0.heading }
    lazy var speed: MutableProperty<Double?> = self.lazyProperty { $0.speed }

    // MARK: Signal Producer
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
                    self.delegate.mutableModel(self, receivedTopicEvent: event)
                    return nil
                }
            }
            .ignoreNil()
            .retry(MutableVehicle.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Vehicle, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Vehicle, NoError>.empty
        }
    }()

    // MARK: Functions
    required init(from vehicle: Vehicle, delegate: MutableModelDelegate) {
        self.code = vehicle.code
        self.delegate = delegate
        self.source = vehicle
    }

    func apply(vehicle: Vehicle) -> Result<(), PSError> {
        if vehicle.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        self.source = vehicle

        self.name <- vehicle.name
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