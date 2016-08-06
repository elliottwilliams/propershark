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

    // MARK: Interal Properties
    internal let connection: ConnectionType
    internal var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Station Support
    internal var source: FromModel
    var identifier: FromModel.Identifier { return self.stopCode }
    var topic: String { return FromModel.topicFor(self.identifier) }
    
    // MARK: Station Attributes
    let stopCode: FromModel.Identifier
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name }
    lazy var description: MutableProperty<String?> = self.lazyProperty { $0.description }
    lazy var position: MutableProperty<Point?> = self.lazyProperty { $0.position }
    lazy var routes: MutableProperty<Set<MutableRoute>?> = self.lazyProperty { ($0.routes?.map(self.attachMutable)).map(Set.init) }
    lazy var vehicles: MutableProperty<Set<MutableVehicle>?> = self.lazyProperty { ($0.vehicles?.map(self.attachMutable)).map(Set.init) }

    // MARK: Signal Producer
    lazy var producer: SignalProducer<Station, NoError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic])
        let future = self.connection.subscribe(self.topic)
        return SignalProducer<SignalProducer<TopicEvent, PSError>, PSError>(values: [now, future])
            .flatten(.Merge)
            .map { (event: TopicEvent) -> Station? in
                switch event {
                case .Meta(.lastEvent(let args, _)):
                    guard let object = args.first else { return nil }
                    return decode(object)
                case .Station(.update(let object, _)):
                    return decode(object)
                default:
                    // Send this event up to the delegate for possible processing
                    self.delegate.mutableModel(self, receivedTopicEvent: event)
                    // its value is now meaningless to us, however
                    return nil
                }
            }
            .ignoreNil()
            .logEvents(identifier: "MutableStation.producer", logger: logSignalEvent)
            .retry(MutableStation.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Station, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Station, NoError>.empty
        }
    }()

    required init(from station: Station, delegate: MutableModelDelegate, connection: ConnectionType) {
        self.stopCode = station.stopCode
        self.delegate = delegate
        self.source = station
        self.connection = connection
    }

    func apply(station: Station) -> Result<(), PSError> {
        if station.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        self.source = station

        self.name <- station.name
        self.description <- station.description
        self.position <- station.position
        
        applyChanges(to: self.routes, from: station.routes)
        applyChanges(to: self.vehicles, from: station.vehicles)

        return .Success()
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

