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
import Argo

class MutableRoute: MutableModel {
    typealias FromModel = Route

    // MARK: Internal Properties
    internal let connection: ConnectionType = Connection.sharedInstance
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Route Support
    internal var source: FromModel
    var identifier: FromModel.Identifier { return self.code }
    var topic: String { return FromModel.topicFor(self.identifier) }

    // MARK: Route Attributes
    let code: FromModel.Identifier
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name }
    lazy var shortName: MutableProperty<String?> = self.lazyProperty { $0.shortName }
    lazy var description: MutableProperty<String?> = self.lazyProperty { $0.description }
    lazy var color: MutableProperty<UIColor?> = self.lazyProperty { $0.color }
    lazy var path:  MutableProperty<[Point]?> = self.lazyProperty { $0.path }
    lazy var stations: MutableProperty<[MutableStation]> = self.lazyProperty { route in
        // Map each static station to a MutableStation, or return an empty array
        route.stations?.map { MutableStation(from: $0, delegate: self.delegate) } ?? []
    }
    lazy var vehicles: MutableProperty<[MutableVehicle]> = self.lazyProperty { route in
        route.vehicles?.map { MutableVehicle(from: $0, delegate: self.delegate) } ?? []
    }

    // MARK: Signal Producer
    lazy var producer: SignalProducer<Route, NoError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic]).map {
            TopicEvent.parseFromRPC("meta.last_event", event: $0)
        }
        let future = self.connection.subscribe(self.topic).map {
            TopicEvent.parseFromTopic(self.topic, event: $0)
        }
        return SignalProducer<SignalProducer<TopicEvent?, PSError>, PSError>(values: [now, future])
            .flatten(.Merge).unwrapOrFail { PSError(code: .parseFailure) }
            .map { (event: TopicEvent) -> Route? in
                switch event {
                case .Meta(.lastEvent(let args, _)):
                    guard let object = args.first else { return nil }
                    return decode(object)
                case .Route(.update(let object, _)):
                    return decode(object)
                case .Route(.vehicleUpdate(let vehicle, _)):
                    self.vehicleUpdate(vehicle)
                    return nil
                default:
                    self.delegate.mutableModel(self, receivedTopicEvent: event)
                    return nil
                }
            }
            .ignoreNil()
            .retry(MutableRoute.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Route, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Route, NoError>.empty
            }
            .on(next: { route in
                self.apply(route)
            })
    }()

    /// If any vehicles on this route match `vehicle`, apply `vehicle` to them, updating their information.
    func vehicleUpdate(vehicle: Vehicle) {
        self.vehicles.value.filter { $0.identifier == vehicle.identifier }
            .forEach { $0.apply(vehicle) }
    }

    // MARK: Functions
    required init(from route: Route, delegate: MutableModelDelegate) {
        self.code = route.code
        self.delegate = delegate
        self.source = route
    }

    func apply(route: Route) -> Result<(), PSError> {
        if route.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        self.source = route

        self.name <- route.name
        self.shortName <- route.shortName
        self.description <- route.description
        self.color <- route.color
        self.path <- route.path
        self.stations <- route.stations?.map { MutableStation(from: $0, delegate: self.delegate) } ?? []
        self.vehicles <- route.vehicles?.map { MutableVehicle(from: $0, delegate: self.delegate) } ?? []

        return .Success()
    }
}

func ==(a: [Point], b: [Point]) -> Bool {
    return true
}
