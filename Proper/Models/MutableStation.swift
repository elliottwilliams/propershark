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

    // MARK: Properties
    let stop_code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.stop_code }
    var topic: String { return FromModel.topicFor(self.identifier) }
    var delegate: MutableModelDelegate
    
    let name: MutableProperty<String?>
    let description: MutableProperty<String?>
    let position: MutableProperty<Point?>

    let routes: MutableProperty<[Route]?>

    internal let connection: ConnectionType = Connection.sharedInstance
    private static let retryAttempts = 3
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

        // Initialize mutable properties with their current values
        self.name = .init(station.name)
        self.description = .init(station.description)
        self.position = .init(station.position)
        self.routes = .init(station.routes)

        // Bind mutable properties to changes from Shark, which implicitly creates a signal and starts listening
        self.name <~ self.producer.map { $0.name }
        self.description <~ self.producer.map { $0.description }
        self.position <~ self.producer.map { $0.position }
        self.routes <~ self.producer.map { $0.routes }
    }

    func apply(station: Station) -> Result<(), PSError> {
        if station.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        
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

