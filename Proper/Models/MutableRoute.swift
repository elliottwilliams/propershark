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
    var identifier: FromModel.Identifier { return self.shortName }
    var topic: String { return FromModel.topicFor(self.identifier) }

    // MARK: Route Attributes
    let shortName: FromModel.Identifier
    lazy var code: MutableProperty<Int?> = self.lazyProperty { $0.code }
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name }
    lazy var description: MutableProperty<String?> = self.lazyProperty { $0.description }
    lazy var color: MutableProperty<UIColor?> = self.lazyProperty { $0.color }
    lazy var path:  MutableProperty<[Point]?> = self.lazyProperty { $0.path }
    lazy var stations: MutableProperty<[MutableStation]?> = self.lazyProperty { ($0.stations?.map(self.attachMutable)) }
    lazy var vehicles: MutableProperty<[MutableVehicle]?> = self.lazyProperty { $0.vehicles?.map(self.attachMutable) }

    // MARK: Signal Producer
    lazy var producer: SignalProducer<Route, NoError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic])
        let future = self.connection.subscribe(self.topic)
        return SignalProducer<SignalProducer<TopicEvent, PSError>, PSError>(values: [now, future])
            .flatten(.Merge)
            .map { (event: TopicEvent) -> Route? in
                switch event {
                case .Meta(.lastEvent(let args, _)):
                    guard let object = args.first else { return nil }
                    return decode(object)
                case .Route(.update(let object, _)):
                    return decode(object)
                case .Route(.vehicleUpdate(let vehicle, _)):
                    self.handleEvent(vehicleUpdate: vehicle)
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
    }()

    // MARK: Functions
    required init(from route: Route, delegate: MutableModelDelegate) {
        self.shortName = route.shortName
        self.delegate = delegate
        self.source = route
    }

    func apply(route: Route) -> Result<(), PSError> {
        if route.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        self.source = route

        self.name <- route.name
        self.code <- route.code
        self.description <- route.description
        self.color <- route.color
        self.path <- route.path
        self.stations <- route.stations?.map(attachMutable)
        self.vehicles <- route.vehicles?.map(attachMutable)

        return .Success()
    }

    // MARK: Event Handlers

    /// If any vehicles on this route match `vehicle`, apply `vehicle` to them, updating their information.
    func handleEvent(vehicleUpdate vehicle: Vehicle) {
        // Atomically modify the vehicles array. `modify` returns the old value, which could be useful to LCS diffing.
        self.vehicles.modify { vehicles in
            // Replace any vehicle whose identifier matches `vehicle`.
            vehicles?.filter { $0 == vehicle }.map { _ in self.attachMutable(from: vehicle) }
        }
    }
}