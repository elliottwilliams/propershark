//
//  Location.swift
//  Proper
//
//  Created by Elliott Williams on 1/3/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveCocoa
import Result

/** A delegate class and signal factory for Proper's integration with Core Location. Use `Location.producer` to get a
 stream of device locations over time.
 */
class Location: NSObject, CLLocationManagerDelegate {
    var observer: Observer<CLLocation, ProperError>

    init(observer: Observer<CLLocation, ProperError>) {
        self.observer = observer
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else {
            return
        }
        observer.sendNext(last)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .authorizedAlways && status != .authorizedWhenInUse {
            observer.sendFailed(.locationDisabled)
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        observer.sendFailed(.locationMonitoringFailed(region: region, error: error))
    }

    static let producer = SignalProducer<CLLocation, ProperError> { observer, disposable in
        let status = CLLocationManager.authorizationStatus()
        guard CLLocationManager.locationServicesEnabled() && status != .restricted && status != .denied else {
            observer.sendFailed(.locationDisabled)
            return
        }

        let manager = CLLocationManager()
        let delegate = Location(observer: observer)
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5.0
        manager.startUpdatingLocation()

        disposable.addDisposable() {
            manager.stopUpdatingLocation()
            delegate // Keep a strong reference to `delegate` in the closure. (`manager.delegate` is weak)
        }
    }.logEvents(identifier: "Location.producer", logger: logSignalEvent)
}
