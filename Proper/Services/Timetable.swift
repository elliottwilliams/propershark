//
//  Timetable.swift
//  Proper
//
//  Created by Elliott Williams on 1/5/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result
import Argo

struct Timetable {
//    typealias Arrival = (eta: NSDate, etd: NSDate)
    static let nextVisit = SignalProducer<Arrival, ProperError> { observer, disposable in

    }

    static func nextVisit(for route: MutableRoute, at station: MutableStation, after beginTime: NSDate,
                              using connection: ConnectionType = Connection.cachedInstance) ->
        SignalProducer<Arrival, ProperError>
    {
        return connection.call("timetable.next_visits",
                               args: [station.identifier, route.identifier, timestamp(beginTime), 1])
            |> decodeArrivals
    }

    private static func decodeArrivals(producer: SignalProducer<TopicEvent, ProperError>) ->
        SignalProducer<Arrival, ProperError>
    {
        return producer.attemptMap({ event -> Result<Decoded<[Arrival]>, ProperError> in
            if case let TopicEvent.Timetable(.arrivals(arrivals)) = event {
                return .Success(arrivals)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).attemptMap({ decoded -> Result<[Arrival], ProperError> in
            switch decoded {
            case .Success(let arrivals):
                return .Success(arrivals)
            case .Failure(let error):
                return .Failure(ProperError.decodeFailure(error: error))
            }
        }).flatMap(.Latest, transform: { arrivals in
            return SignalProducer<Arrival, ProperError>(values: arrivals)
        })
    }

    static var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm:ss"
        return formatter
    }()

    private static func timestamp(date: NSDate) -> String {
        return formatter.stringFromDate(date)
    }
}
