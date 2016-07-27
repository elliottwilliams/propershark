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

    // MARK: Properties
    let code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.code }
    var topic: String { return FromModel.topicFor(self.identifier) }
    var delegate: MutableModelDelegate

    let name: MutableProperty<String?>
    let shortName: MutableProperty<String?>
    let description: MutableProperty<String?>
    let color: MutableProperty<UIColor?>
    let path:  MutableProperty<[Point]?>
    let stations: MutableProperty<[Station]?>

    internal let connection: ConnectionType = Connection.sharedInstance
    private static let retryAttempts = 3
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
                default:
                    return nil
                }
            }
            .unwrapOrFail { PSError(code: .decodeFailure) }
            .retry(MutableRoute.retryAttempts)
            .flatMapError { (error: PSError) -> SignalProducer<Route, NoError> in
                self.delegate.mutableModel(self, receivedError: error)
                return SignalProducer<Route, NoError>.empty
        }
    }()


    required init(from route: Route, delegate: MutableModelDelegate) {
        self.code = route.code
        self.delegate = delegate

        // Initialize mutable properties with current values of the passed
        // route.
        self.name = .init(route.name)
        self.shortName = .init(route.shortName)
        self.description = .init(route.description)
        self.color = .init(route.color)
        self.path = .init(route.path)
        self.stations = .init(route.stations)

        // Bind future values
        self.name <~ self.producer.map { $0.name }
        self.shortName <~ self.producer.map { $0.shortName }
        self.description <~ self.producer.map { $0.description }
        self.color <~ self.producer.map { $0.color }
        self.path <~ self.producer.map { $0.path }
        self.stations <~ self.producer.map { $0.stations }
    }

    func apply(route: Route) -> Result<(), PSError> {
        if route.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }

        self.name <- route.name
        self.shortName <- route.shortName
        self.description <- route.description
        self.color <- route.color
        self.path <- route.path

        return .Success()
    }
}

func ==(a: [Point], b: [Point]) -> Bool {
    return true
}
