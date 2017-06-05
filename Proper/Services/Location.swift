//
//  Location.swift
//  Proper
//
//  Created by Elliott Williams on 1/3/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Result

/** A delegate class and signal factory for Proper's integration with Core Location. Use `Location.producer` to get a
 stream of device locations over time.
 */
class Location: NSObject, CLLocationManagerDelegate {
  let observer: Observer<CLLocation, ProperError>
  let disposable: CompositeDisposable
  var status: CLAuthorizationStatus

  init(observer: Observer<CLLocation, ProperError>, disposable: CompositeDisposable,
       status: CLAuthorizationStatus = CLLocationManager.authorizationStatus())
  {
    self.observer = observer
    self.disposable = disposable
    self.status = status
    super.init()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let last = locations.last else {
      return
    }
    observer.send(value: last)
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch (self.status, status) {
    case (_, .restricted), (_, .denied):
      // Shut down this producer if location is disabled.
      observer.send(error: .locationDisabled)
    case (.notDetermined, .authorizedAlways), (.notDetermined, .authorizedWhenInUse),
         (.restricted, .authorizedAlways), (.restricted, .authorizedWhenInUse),
         (.denied, .authorizedAlways), (.denied, .authorizedWhenInUse):
      // Restart delivery of location events.
      manager.stopUpdatingLocation()
      manager.startUpdatingLocation()
    default:
      break
    }

    self.status = status
  }

  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    observer.send(error: .locationMonitoringFailed(region: region, error: error))
  }

  static let producer = SignalProducer<CLLocation, ProperError> { observer, disposable in
    let manager = CLLocationManager()
    switch CLLocationManager.authorizationStatus() {
    case .restricted, .denied:
      observer.send(error: .locationDisabled)
      return
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      break
    }

    let delegate = Location(observer: observer, disposable: disposable)
    let delegateReference = Unmanaged.passRetained(delegate)

    manager.delegate = delegate
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = 5.0
    manager.startUpdatingLocation()

    disposable.add {
      manager.stopUpdatingLocation()
      delegateReference.release()
    }
    }.logEvents(identifier: "Location.producer", logger: logSignalEvent)
}
