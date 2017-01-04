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

class Location: NSObject, CLLocationManagerDelegate {
    var observer: Observer<CLLocation?, ProperError>

    init(observer: Observer<CLLocation?, ProperError>) {
        self.observer = observer
        super.init()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        observer.sendNext(locations.last)
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .AuthorizedAlways && status != .AuthorizedWhenInUse {
            observer.sendFailed(.locationDisabled)
        }
    }

    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        observer.sendFailed(.locationMonitoringFailed(region: region, error: error))
    }

    static let producer = SignalProducer<CLLocation?, ProperError> { observer, disposable in
        let status = CLLocationManager.authorizationStatus()
        guard CLLocationManager.locationServicesEnabled() && status != .Restricted && status != .Denied else {
            observer.sendFailed(.locationDisabled)
            return
        }

        let manager = CLLocationManager()
        let delegate = Location(observer: observer)
        if status == .NotDetermined {
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

    }
}
