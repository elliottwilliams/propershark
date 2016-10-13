//
//  NearbyStationsViewModel.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result

class NearbyStationsViewModel: NSObject, UITableViewDataSource, MutableModelDelegate {

    let point: AnyProperty<Point>
    let stations: AnyProperty<[Station]>

    internal let connection: ConnectionType
    internal let disposable = CompositeDisposable()

    init(point: AnyProperty<Point>, connection: ConnectionType = Connection.sharedInstance) {
        self.point = point
        self.connection = connection
    }

    /**
     Returns a signal producer that emits stations inside the given MKMapRect.

     Implementation note: The signal producer returned calls `agency.stations`, which returns *all* stations for the
     agency and is thus very slow.
     */
    func findStations(within rect: MKMapRect) -> SignalProducer<MutableStation, ProperError> {
        var mutables: [Station: (station: MutableStation, disposable: Disposable)] = [:]

        return connection.call("agency.stations").attemptMap({ event -> Result<[AnyObject], ProperError> in
            // Received events should be Agency.stations events, which contain a list of all stations on the agency.
            if case .Agency(.stations(let stations)) = event {
                return .Success(stations)
            } else {
                return .Failure(ProperError.eventParseFailure)
            }
        }).decodeAnyAs(Station.self).flatMap(.Latest, transform: { stations in
            // Convert the list of stations into a signal producer that emits stations one at a time. Since
            // connection.call completes after receiving one response, the producer created here will complete after
            // emitting each station once.
            return SignalProducer<Station, ProperError>(values: stations)
        }).map({ station -> MutableStation? in
            // As stations are discovered, the ones within `rect` need to be expanded to MutableStations and subscribed
            // to, so we can learn about their arrivals.
            guard let position = station.position else { return nil }
            let mutable = mutables[station]
            let contained = MKMapRectContainsPoint(rect, MKMapPoint(point: position))

            // The action taken depends on whether we already have a MutableStation in memory for this station, and
            // whether this station is within `rect`.
            switch (mutable != nil, contained) {
            case (true, true):
                // Return a MutableStation that we already have and that we are still interested in.
                return mutable!.station
            case (true, false):
                // Dispose of and remove a MutableStation that we no longer are interested in.
                mutable!.disposable.dispose()
                mutables[station] = nil
                return nil
            case (false, true):
                // Create, store, and return a MutableStation if we don't have one yet, but it is in range.
                if let mutable = try? MutableStation(from: station, delegate: self, connection: self.connection) {
                    mutables[station] = (mutable, mutable.producer.startWithFailed({ _ in /* handle failure */ }))
                    return mutable
                } else {
                    return nil
                }
            case (false, false):
                // Ignore stations that are out of range.
                return nil
            }
        }).ignoreNil()
    }

    // MARK: Table View Data Source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return stations.value.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        <#code#>
    }
}
