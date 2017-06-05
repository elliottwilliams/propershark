//
//  POIMapViewController.swift
//  Proper
//
//  Created by Elliott Williams on 5/29/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import MapKit
import Result

class POIMapViewController: UIViewController, ProperViewController {
  typealias DisposableType = ScopedDisposable<CompositeDisposable>

  var map: MKMapView { return self.view as! MKMapView }
  let onSelect: Action<MutableStation, (), NoError>
  let routes: Property<Set<MutableRoute>>

  // Mutable properties that can be set by the map to impact the POI search region.
  let center: MutableProperty<Point>
  let zoom: MutableProperty<CLLocationDistance>


  let isUserLocation: Property<Bool>
  var staticCenter: MKPointAnnotation? = nil

  fileprivate var polylines = [MutableRoute: MKPolyline]()
  fileprivate var routeForPolyline = [MKPolyline: MutableRoute]()

  var connection: ConnectionType
  var disposable = ScopedDisposable(CompositeDisposable())

  init(center: MutableProperty<Point>,
       zoom: MutableProperty<CLLocationDistance>,
       routes: Property<Set<MutableRoute>>,
       onSelect: Action<MutableStation, (), NoError>,
       isUserLocation: Property<Bool>,
       connection: ConnectionType = Connection.cachedInstance)
  {
    self.center = center
    self.zoom = zoom
    self.routes = routes
    self.onSelect = onSelect
    self.isUserLocation = isUserLocation
    self.connection = connection
    super.init(nibName: nil, bundle: nil)

    map.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = MKMapView()
    view.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: Lifecycle

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    disposable += center.producer.combineLatest(with: zoom.producer).startWithValues { point, zoom in
      // Update the map as the center and zoom level changes. Center is expected to change following device location.
      let coordinate = CLLocationCoordinate2D(point: point)
      self.map.setCenter(coordinate, animated: true)
      let boundingRegion = MKCoordinateRegionMakeWithDistance(coordinate, zoom, zoom)
      self.map.setRegion(self.map.regionThatFits(boundingRegion), animated: true)
      self.staticCenter?.coordinate = coordinate
    }

    disposable += isUserLocation.producer.startWithValues { value in
      // Depending on whether the map is tracking user location, show the appropriate annotation.
      if value {
        self.map.showsUserLocation = true
        self.staticCenter = nil
      } else {
        // Clear current center annotation.
        self.map.showsUserLocation = false
        self.staticCenter.map(self.map.removeAnnotation)

        // Create a new center annotation.
        let point = MKPointAnnotation()
        point.coordinate = CLLocationCoordinate2D(point: self.center.value)
        self.map.addAnnotation(point)
        self.staticCenter = point
      }
    }

    disposable += routes.producer.flatMap(.latest, transform: { routes -> SignalProducer<Void, NoError> in
      // Show route polyline annotations, updating as the routes change. The parent POIViewController will only
      // provide routes inside the current search region.
      let annotationProducers = routes.map(self.polyline(for:))
      return SignalProducer(annotationProducers).flatten(.merge)
    }).start()
  }

  override func viewDidDisappear(_ animated: Bool) {
    disposable.dispose()
    disposable = ScopedDisposable(CompositeDisposable())
    super.viewDidDisappear(animated)
  }

  // MARK: Map annotations

  func polyline(for route: MutableRoute) -> SignalProducer<Void, NoError> {
    let producer = route.canonical.producer.skipNil().map({ route -> MKPolyline in
      let points = route.stations.map({ stop in stop.station.position.value })
        .flatMap({ $0 })
        .map({ MKMapPoint(point: $0) })
      return MKPolyline(points: UnsafePointer(points), count: points.count)
    }).map(Optional.some)

    return producer.skipRepeats(==).combinePrevious(nil).on(value: { prev, next in
      if let prev = prev {
        self.map.removeAnnotation(prev)
        self.routeForPolyline[prev] = nil
      }
      if let next = next {
        self.map.addAnnotation(next)
        self.routeForPolyline[next] = route
      }
    }).map({ _, _ in () })
  }

  func annotations(for station: MutableStation) -> [POIStationAnnotation] {
    return self.map.annotations.flatMap({ $0 as? POIStationAnnotation })
      .filter({ $0.station == station })
  }
  func stations(within range: CountableClosedRange<Int>) -> [POIStationAnnotation] {
    return map.annotations.flatMap({ ($0 as? POIStationAnnotation) })
      .filter({ range.contains($0.index) })
  }
  func stations(from idx: Int) -> [POIStationAnnotation] {
    return map.annotations.flatMap({ ($0 as? POIStationAnnotation) })
      .filter({ $0.index >= idx })
  }

  func addAnnotation(for station: MutableStation, at idx: Int) {
    guard let position = station.position.value else {
      return
    }
    let distanceString = POIViewModel.distanceString(self.center.producer.map({ ($0, position) }))
    let annotation = POIStationAnnotation(station: station,
                                          locatedAt: position,
                                          index: idx,
                                          distance: distanceString)
    stations(from: idx).forEach { $0.index += 1 }
    map.addAnnotation(annotation)
  }

  func deleteAnnotations(for station: MutableStation) {
    let annotations = self.annotations(for: station)
    let idx = annotations.min(by: { $0.index < $1.index }).map({ $0.index })!
    map.removeAnnotations(annotations)
    self.stations(from: idx+1).forEach { $0.index -= 1 }
  }

  func reorderAnnotations(withIndex fi: Int, to ti: Int) {
    if fi < ti {
      self.stations(within: fi...ti).forEach { annotation in
        switch annotation.index {
        case fi: annotation.index = ti
        case _:  annotation.index -= 1
        }
      }
    } else {
      self.stations(within: ti...fi).forEach { annotation in
        switch annotation.index {
        case fi: annotation.index = ti
        case _:  annotation.index += 1
        }
      }
    }
  }
}

// MARK: - Map view delegate
extension POIMapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? POIStationAnnotation {
      let view =
        mapView.dequeueReusableAnnotationView(withIdentifier: "stationAnnotation") as? POIStationAnnotationView
          ?? POIStationAnnotationView(annotation: annotation, reuseIdentifier: "stationAnnotation")
      view.apply(annotation: annotation)
      return view
    }

    // Returning nil causes the map to use a default annotation.
    return nil
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    // Render a route on the map.
    if let line = overlay as? MKPolyline, let route = routeForPolyline[line] {
      let renderer = MKPolylineRenderer()
      disposable += route.color.producer.startWithValues { renderer.strokeColor = $0 }
      renderer.lineWidth = 5.0
      return renderer
    }

    // The default:
    return MKOverlayRenderer()
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    if let station = ((view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation)?.station {
      self.parent?.performSegue(withIdentifier: "showStation", sender: station)
    }
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

    if let annotation = (view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation {
      disposable += onSelect.apply(annotation.station).start()
      //            let section = table.dataSource.index(of: annotation.station)
      //            let row = (table.dataSource.arrivals[section].isEmpty) ? NSNotFound : 0
      //            table.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .top,
      //                                        animated: true)
    }
  }

  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    // Update the search region by modifying `center` and `zoom`.
    // Called repeatedly as the map is being scrolled. We'll need to throttle the search itself or the property updates
    // to prevent from overwhelming the system with search requests.
    //        map.visibleMapRect
  }
}
