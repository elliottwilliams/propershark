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
    internal let connection: ConnectionType
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Route Support
    internal var source: FromModel
    var identifier: FromModel.Identifier { return self.shortName }
    var topic: String { return FromModel.topicFor(self.identifier) }

    // MARK: Route Attributes
    let shortName: FromModel.Identifier
    lazy var code: MutableProperty<Int?> = self.lazyProperty { $0.code }
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name ?? $0.shortName }
    lazy var description: MutableProperty<String?> = self.lazyProperty { $0.description }
    lazy var color: MutableProperty<UIColor?> = self.lazyProperty { $0.color }
    lazy var path:  MutableProperty<[Point]?> = self.lazyProperty { $0.path }
    lazy var stations: MutableProperty<Set<MutableStation>?> = self.lazyProperty { ($0.stations?.map(self.attachMutable)).map(Set.init) }
    lazy var vehicles: MutableProperty<Set<MutableVehicle>?> = self.lazyProperty { ($0.vehicles?.map(self.attachMutable)).map(Set.init) }

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
            .on(next: { self.apply($0) })
            .logEvents(identifier: "MutableRoute.producer", logger: logSignalEvent)
    }()

    // MARK: Functions
    required init(from route: Route, delegate: MutableModelDelegate,
                       connection: ConnectionType = Connection.sharedInstance)
    {
        self.shortName = route.shortName
        self.delegate = delegate
        self.source = route
        self.connection = connection
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
        self.path <-| route.path

        applyChanges(to: self.stations, from: route.stations)
        applyChanges(to: self.vehicles, from: route.vehicles)

        return .Success()
    }

    // MARK: Event Handlers

    /// If any vehicles on this route match `vehicle`, update their information to match `vehicle`.
    func handleEvent(vehicleUpdate vehicle: Vehicle) {
        self.vehicles.value?.filter { $0 == vehicle }.forEach { $0.apply(vehicle) }
    }
}