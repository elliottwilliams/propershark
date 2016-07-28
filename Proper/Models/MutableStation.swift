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
    internal let connection: ConnectionType = Connection.sharedInstance
    var delegate: MutableModelDelegate
    private static let retryAttempts = 3

    // MARK: Station Support
    internal var source: FromModel
    var identifier: FromModel.Identifier { return self.stop_code }
    var topic: String { return FromModel.topicFor(self.identifier) }
    
    // MARK: Station Attributes
    let stop_code: FromModel.Identifier
    lazy var name: MutableProperty<String?> = self.lazyProperty { $0.name }
    lazy var description: MutableProperty<String?> = self.lazyProperty { $0.description }
    lazy var position: MutableProperty<Point?> = self.lazyProperty { $0.position }
    lazy var routes: MutableProperty<[MutableRoute]> = self.lazyProperty { station in
        // Map each static route to a MutableRoute or return an empty array
        station.routes?.map { MutableRoute(from: $0, delegate: self.delegate) } ?? []
    }
    lazy var vehicles: MutableProperty<[MutableVehicle]> = self.lazyProperty { station in
        station.vehicles?.map { MutableVehicle(from: $0, delegate: self.delegate) } ?? []
    }

    // MARK: Signal Producer
    lazy var producer: SignalProducer<Station, NoError> = {
        let now = self.connection.call("meta.last_event", args: [self.topic, self.topic]).map {
            TopicEvent.parseFromRPC("meta.last_event", event: $0)
        }
        let future = self.connection.subscribe(self.topic).map {
            TopicEvent.parseFromTopic(self.topic, event: $0)
        }
        return SignalProducer<SignalProducer<TopicEvent?, PSError>, PSError>(values: [now, future])
            .flatten(.Merge).unwrapOrFail { PSError(code: .parseFailure) }
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
            .retry(MutableStation.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Station, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Station, NoError>.empty
        }
    }()


    required init(from station: Station, delegate: MutableModelDelegate) {
        self.stop_code = station.stop_code
        self.delegate = delegate
        self.source = station
    }

    func apply(station: Station) -> Result<(), PSError> {
        if station.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        self.source = station
        
        self.name <- station.name
        self.description <- station.description
        self.position <- station.position

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

