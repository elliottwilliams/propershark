//
//  MutableStation.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import Argo

class MutableStation: MutableModel {
    typealias FromModel = Station
    typealias RouteType = MutableRoute
    typealias VehicleType = MutableVehicle

    // MARK: Interal Properties
    internal let connection: ConnectionType
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Station Support
    var identifier: FromModel.Identifier { return self.stopCode }
    var topic: String { return FromModel.topicFor(self.identifier) }
    
    // MARK: Station Attributes
    let stopCode: FromModel.Identifier
    var name: MutableProperty<String?> = .init(nil)
    var description: MutableProperty<String?> = .init(nil)
    var position: MutableProperty<Point?> = .init(nil)
    var routes: MutableProperty<Set<RouteType>?> = .init(nil)
    var vehicles: MutableProperty<Set<VehicleType>?> = .init(nil)

    // MARK: Signal Producer
    lazy var producer: SignalProducer<TopicEvent, ProperError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic])
        let future = self.connection.subscribe(self.topic)
        return SignalProducer<SignalProducer<TopicEvent, ProperError>, ProperError>(values: [now, future])
            .flatten(.Merge)
            .logEvents(identifier: "MutableStation.producer", logger: logSignalEvent)
            .attempt(self.handleEvent)
    }()

    required init(from station: Station, delegate: MutableModelDelegate, connection: ConnectionType) throws {
        self.stopCode = station.stopCode
        self.delegate = delegate
        self.connection = connection
        try apply(station)
    }

    func handleEvent(event: TopicEvent) -> Result<(), ProperError> {
        if let error = event.error {
            return .Failure(.decodeFailure(error: error))
        }

        do {
            switch event {
            case .Station(.update(let station, _)):
                try self.apply(station.value!)
            default:
                self.delegate.mutableModel(self, receivedTopicEvent: event)
            }
        } catch let error as ProperError {
            return .Failure(error)
        } catch {
            return .Failure(.unexpected(error: error))
        }
        return .Success()
    }

    func apply(station: Station) throws {
        if station.identifier != self.identifier {
            throw ProperError.applyFailure(from: station.identifier, onto: self.identifier)
        }

        self.name <- station.name
        self.description <- station.description
        self.position <- station.position
        
        try attachOrApplyChanges(to: self.routes, from: station.routes)
        try attachOrApplyChanges(to: self.vehicles, from: station.vehicles)
    }


    // MARK: Nested Types
    class Annotation: NSObject, MKAnnotation {
        @objc var coordinate: CLLocationCoordinate2D
        @objc var title: String?
        @objc var subtitle: String?

        /// Create an annotation for the given station, at a given point (which is passed independently since we can't
        /// always ensure that a MutableStation has a `position`)
        init(from station: MutableStation, at point: Point) {
            // Establish starting coordinates
            self.coordinate = CLLocationCoordinate2D(point: point)
            super.init()

            // Bind current and future values of the station to annotation properties
            station.position.map { point in
                if let point = point {
                    self.coordinate = CLLocationCoordinate2D(point: point)
                }
            }
            station.name.map { self.title = $0 }
            station.description.map { self.subtitle = $0 }
        }
    }
}

