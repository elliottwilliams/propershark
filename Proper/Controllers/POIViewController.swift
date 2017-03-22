//
//  POIViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate, MKMapViewDelegate {
    // MARK: Point properties
    typealias NamedPoint = POIViewModel.NamedPoint

    /// Map annotation for the point of interest represented by this view. Only used for static locations.
    let annotation = MKPointAnnotation()

    /// The point tracked by the POI view. May be either the user's location or a static point. While the view is
    /// visible, this point is from `staticLocation` or `deviceLocation`, depending on whether a static location was
    /// passed.
    lazy var point = MutableProperty<Point?>(nil)
    lazy var zoom = MutableProperty<CLLocationDistance>(250) // Default zoom of 250m

    // Stations found within the map area. This producer is passed to the POITableViewController and is a basis for its
    // view model.
    lazy var stations = MutableProperty<[MutableStation]>([])

    /// A producer for the device's location, which adds metadata used by the view into the signal. It is started when
    /// the view appears, but is interrupted if a static location is passed by `staticLocation`.
    let deviceLocation = Location.producer |> POIViewModel.distinctLocations

    /// A producer for a "static location" of the view. This static location overrides the device location and makes the
    /// view represent the latest point passed.
    var staticLocation = SignalProducer<NamedPoint, ProperError>.never

    /// A producer that merges `deviceLocation` and `staticLocation`. The device location will be used until 
    /// `staticLocation` emits a `NamedPoint`, at which point the producer is replaced by `staticLocation`.
    var location: SignalProducer<NamedPoint, ProperError> {
        return deviceLocation.takeUntilReplacement(staticLocation)
    }

    // MARK: UI properties
    @IBOutlet weak var map: MKMapView!

    // MARK: Conformances
    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    // MARK: UI updates

    // TODO - when map is zoomed in/out, update `self.zoom`.

    func updateMap(point: Point, isUserLocation: Bool) {
        let coordinate = CLLocationCoordinate2D(point: point)
        map.setCenterCoordinate(coordinate, animated: true)
        let boundingRegion = MKCoordinateRegionMakeWithDistance(coordinate, zoom.value, zoom.value)
        map.setRegion(map.regionThatFits(boundingRegion), animated: true)

        // DEBUG - show search area around point
        let circle = MKCircle(centerCoordinate: coordinate, radius: zoom.value)
        map.addOverlay(circle)
        
        if isUserLocation {
            map.showsUserLocation = true
        } else {
            annotation.coordinate = coordinate
            map.addAnnotation(annotation)
        }
    }

    // MARK: Map annotations

    func annotations(for station: MutableStation) -> [POIStationAnnotation] {
        return self.map.annotations.flatMap({ $0 as? POIStationAnnotation })
            .filter({ $0.station == station })
    }
    func annotations(for station: MutableStation) -> [MKAnnotation] {
        let pois: [POIStationAnnotation] = annotations(for: station)
        return pois.map({ $0 as MKAnnotation })
    }

    func addAnnotation(for station: MutableStation, at index: Int) {
        guard let position = station.position.value else {
            return
        }
        let distanceString = POIViewModel.distanceString(self.point.producer.ignoreNil()
            .map({ ($0, position) }))
        let badge = Badge(alphabetIndex: index, seedForColor: station)
        let annotation = POIStationAnnotation(station: station, located: position, badge: badge,
                                              distance: distanceString)
        self.map.addAnnotation(annotation)
    }

    func deleteAnnotations(for station: MutableStation) {
        map.removeAnnotations(annotations(for: station))
    }

    func rebadge(station: MutableStation, index: Int) {
        annotations(for: station).forEach { (annotation: POIStationAnnotation) in
            annotation.badge.name.swap(Badge.letterForIndex(index))
        }
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self

        // Initially show the default region for the agency.
        map.region = map.regionThatFits(Config.agency.region)

        // Clear the title until the signals created in `viewWillAppear` set one.
        navigationItem.title = nil
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Make the navigation bar fully transparent.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }

        // Search for nearby stations.
        disposable += NearbyStationsViewModel.chain(connection, producer:
            combineLatest(point.producer.ignoreNil(), zoom.producer)
            .logEvents(identifier: "NearbyStationsViewModel.chain input", logger: logSignalEvent))
            .startWithResult() { result in
                switch result {
                case let .Success(stations):    self.stations.swap(stations)
                case let .Failure(error):       self.displayError(error)
                }
            }

        // Using location, update the map.
        disposable += location.startWithResult { result in
            switch result {
            case let .Success(point, name, userLocation):
                self.point.swap(point)
                self.navigationItem.title = name
                self.updateMap(point, isUserLocation: userLocation)
            case let .Failure(error):
                self.displayError(error)
            }
        }

        // Show nearby stations on the map.
        disposable += POIViewModel.chain(connection, producer: stations.producer).startWithResult({ result in
            switch result {
            case let .Failure(error):
                self.displayError(error)
            case let .Success(.addStation(station, index: idx)):
                self.addAnnotation(for: station, at: idx)
            case let .Success(.deleteStation(station)):
                self.deleteAnnotations(for: station)
            case let .Success(.reorderStation(station, index: idx)):
                self.rebadge(station, index: idx)
            default: break
            }
        })
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // Reset the navigation bar.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        disposable.dispose()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "embedPOITable":
            let dest = segue.destinationViewController as! POITableViewController
            dest.stations = stations.producer
            dest.mapPoint = point.producer.ignoreNil()
        case "showStation":
            let station = sender as! MutableStation
            let dest = segue.destinationViewController as! StationViewController
            dest.station = station
        default:
            return
        }
    }

    // MARK: Map view delegate

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? POIStationAnnotation {
            let view =
                mapView.dequeueReusableAnnotationViewWithIdentifier("stationAnnotation") as? POIStationAnnotationView
                    ?? POIStationAnnotationView(annotation: annotation, reuseIdentifier: "stationAnnotation")
            view.apply(annotation)
            return view
        }

        // Returning nil causes the map to use a default annotation.
        return nil
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor.skyBlueColor().colorWithAlphaComponent(0.1)
        return renderer
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let station = ((view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation)?.station {
            performSegueWithIdentifier("showStation", sender: station)
        }
    }
}
