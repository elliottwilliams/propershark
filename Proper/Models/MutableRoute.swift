//
//  MutableRoute.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import Argo
import UIKit

class MutableRoute: MutableModel, Comparable {
    typealias FromModel = Route
    typealias StationType = MutableStation
    typealias VehicleType = MutableVehicle

    // MARK: Internal Properties
    internal let connection: ConnectionType
    private static let retryAttempts = 3

    // MARK: Route Support
    var identifier: FromModel.Identifier { return self.shortName }
    var topic: String { return FromModel.topic(for: self.identifier) }

    // MARK: Route Attributes
    let shortName: FromModel.Identifier
    var code: MutableProperty<Int?> = .init(nil)
    var name: MutableProperty<String?> = .init(nil)
    var description: MutableProperty<String?> = .init(nil)
    var color: MutableProperty<UIColor?> = .init(nil)
    var path:  MutableProperty<[Point]?> = .init(nil)
    var stations: MutableProperty<Set<StationType>> = .init(Set())
    var vehicles: MutableProperty<Set<VehicleType>> = .init(Set())
    var itinerary: MutableProperty<[StationType]?> = .init(nil)
    var canonical: MutableProperty<CanonicalRoute<StationType>?> = .init(nil)

    // MARK: Signal Producer
    lazy var producer: SignalProducer<TopicEvent, ProperError> = {
        let now = self.connection.call("meta.last_event", with: [self.topic, self.topic])
        let future = self.connection.subscribe(to: self.topic)
        return SignalProducer<SignalProducer<TopicEvent, ProperError>, ProperError>([now, future])
            .flatten(.merge)
            .logEvents(identifier: "MutableRoute.producer", logger: logSignalEvent)
            .attempt(operation: self.handle)
    }()

    // MARK: Functions
    required init(from route: Route, connection: ConnectionType) throws {
        self.shortName = route.shortName
        self.connection = connection
        try apply(route)

        // Create back-references to this MutableRoute on all vehicles associated with the route.
        // Disabled 2017-05-16 during swift3 migration
        //self.vehicles.producer.flatten().startWithValues { [weak self] vehicle in
        //    vehicle.route.modify { $0 ?? self }
        //}
    }


    func handle(event: TopicEvent) -> Result<(), ProperError> {
        if let error = event.error {
            return .failure(.decodeFailure(error))
        }

        return ProperError.capture({
            switch event {
            case .route(.update(let route, _)):
                try self.apply(route.value!)
            case .route(.vehicleUpdate(let vehicle, _)):
                // If any vehicles on this route match `vehicle`, update their information to match `vehicle`.
                try self.vehicles.value.filter { $0 == vehicle.value! }.forEach { try $0.apply(vehicle.value!) }
            default: break
            }
        })
    }

    func apply(_ route: Route) throws {
        if route.identifier != self.identifier {
            throw ProperError.applyFailure(from: route.identifier, onto: self.identifier)
        }

        self.name <- route.name
        self.code <- route.code
        self.description <- route.description
        self.color <- route.color
        self.path <-| route.path

        try attachOrApplyChanges(to: self.stations, from: route.stations)
        try attachOrApplyChanges(to: self.vehicles, from: route.vehicles)

        // Map the station stubs in `route.stations` to mutables in `self.stations`, then update the itinerary property
        // and regenerate the condensed route *iff the stations or their ordering has changed*.
        if let itinerary = try route.itinerary.map(mappedItinerary), self.itinerary.value.map({ $0 != itinerary }) ?? true {
            self.itinerary.value = itinerary
            self.canonical.value = CanonicalRoute(from: itinerary)
        }
    }

    /// Map an itinerary of static Stations to MutableStations contained by this object's `stations` set.
    func mappedItinerary(source: [Station]) throws -> [MutableStation] {
        let mutables = self.stations.value
        let dict: [Station.Identifier: MutableStation] = mutables.reduce([:]) { dict, station in
            var dict = dict
            dict[station.identifier] = station
            return dict
        }
        return try source.map { station in
            guard let mutable = dict[station.identifier] else {
                throw ProperError.stateInconsistency(
                    description: "Expected mutable for \(station.identifier) to exist in the set",
                    within: self
                )
            }
            return mutable
        }
    }

    func snapshot() -> FromModel {
        return Route(shortName: shortName, code: code.value, name: name.value, description: description.value,
                     color: color.value, path: path.value,
                     stations: stations.value.map({ $0.snapshot() }),
                     vehicles: vehicles.value.map({ $0.snapshot() }),
                     itinerary: itinerary.value?.map({ $0.snapshot() }))
    }
}

func < (a: MutableRoute, b: MutableRoute) -> Bool {
    return a.identifier < b.identifier
}
