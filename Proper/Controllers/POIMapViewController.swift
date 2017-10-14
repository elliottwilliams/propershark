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
import Dwifft

class POIMapViewController: UIViewController, ProperViewController {
  typealias DisposableType = ScopedDisposable<CompositeDisposable>

  var map: MKMapView { return self.view as! MKMapView }
  let onSelect: Action<MutableStation, (), NoError>
  let routes: Property<Set<MutableRoute>>
  let stations: Property<[MutableStation]>

  // Mutable properties that can be set by the map to impact the POI search region.
  let center: MutableProperty<Point>
  let zoom: MutableProperty<MKCoordinateSpan>

  let isUserLocation: Property<Bool>
  var staticCenter: MKPointAnnotation? = nil

  var shouldShowStationAnnotations: Bool {
    // Hide station annotations above 2km
    return map.region.span.latitudeDelta < 2.0/111
  }

  fileprivate var stationForAnnotationView = NSMapTable<MKAnnotationView, MutableStation>()
  fileprivate var polylines = [MutableRoute: MKPolyline]()
  fileprivate var routeForPolyline = [MKPolyline: MutableRoute]()
  fileprivate let updateRegionLock = NSLock()
  fileprivate var viewDidLayout = false

  var disposable = ScopedDisposable(CompositeDisposable())

  init(center: MutableProperty<Point>,
       zoom: MutableProperty<MKCoordinateSpan>,
       routes: Property<Set<MutableRoute>>,
       stations: Property<[MutableStation]>,
       onSelect: Action<MutableStation, (), NoError>,
       isUserLocation: Property<Bool>)
  {
    self.center = center
    self.zoom = zoom
    self.routes = routes
    self.stations = stations
    self.onSelect = onSelect
    self.isUserLocation = isUserLocation
    super.init(nibName: nil, bundle: nil)

    map.translatesAutoresizingMaskIntoConstraints = false
    map.region = MKCoordinateRegion(center: CLLocationCoordinate2D(point: center.value),
                                    span: zoom.value)
    map.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = MKMapView()
  }

  // MARK: Lifecycle

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    disposable += center.producer.combineLatest(with: zoom.producer).startWithValues { point, zoom in
      guard self.updateRegionLock.try() else {
        return
      }

      // Update the map as the center and zoom level changes. Center is expected to change following device location.
      let coordinate = CLLocationCoordinate2D(point: point)
      let boundingRegion = MKCoordinateRegion(center: coordinate, span: zoom)
      self.map.setRegion(boundingRegion, animated: true)
      self.staticCenter?.coordinate = coordinate
      self.updateRegionLock.unlock()
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

    disposable += stations.producer
      .filter({ _ in self.shouldShowStationAnnotations })
      .map(Set.init).combinePrevious(Set()).startWithValues { prev, next in
        self.map.removeAnnotations(prev.filter(next.contains))
        self.map.addAnnotations(next.filter(prev.contains))
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

  override func viewDidLayoutSubviews() {
    viewDidLayout = true
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

  func contains(point: Point) -> Bool {
    return MKMapRectContainsPoint(map.visibleMapRect, MKMapPoint(point: point))
  }
}

// MARK: - Map view delegate
extension POIMapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if let annotation = annotation as? MutableStation {
      let view = mapView.dequeueReusableAnnotationView(withIdentifier: "station") as? MKMarkerAnnotationView ??
        MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "station")
      stationForAnnotationView.setObject(annotation, forKey: view)
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

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    if let station = stationForAnnotationView.object(forKey: view) {
      disposable += onSelect.apply(station).start()
    }
  }

  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    guard viewDidLayout, updateRegionLock.try() else {
      return
    }
    // TODO: I shouldn't update the center point, because that's based on the nearby view's representative location.
    // But I should make sure whatever region shown by the map is being searched.
//    center.swap(Point(coordinate: mapView.region.center))
//    zoom.swap(mapView.region.span)
    updateRegionLock.unlock()

    if shouldShowStationAnnotations {
      map.addAnnotations(self.stations.value)
    } else {
      map.removeAnnotations(self.stations.value)
    }
  }
}
