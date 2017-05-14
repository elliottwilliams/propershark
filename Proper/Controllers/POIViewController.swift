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

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate {
    // MARK: Point properties
    typealias NamedPoint = POIViewModel.NamedPoint

    /// Map annotation for the point of interest represented by this view. Only used for static locations.
    let annotation = MKPointAnnotation()

    var table: POITableViewController?

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

    func updateMap(center point: Point, isUserLocation: Bool) {
        let coordinate = CLLocationCoordinate2D(point: point)
        map.setCenter(coordinate, animated: true)
        let boundingRegion = MKCoordinateRegionMakeWithDistance(coordinate, zoom.value, zoom.value)
        map.setRegion(map.regionThatFits(boundingRegion), animated: true)
        
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
    func annotations(within range: Range<Int>) -> [POIStationAnnotation] {
        return map.annotations.flatMap({ ($0 as? POIStationAnnotation) })
            .filter({ range.contains($0.index) })
    }
    func annotations(from idx: Int) -> [POIStationAnnotation] {
        return map.annotations.flatMap({ ($0 as? POIStationAnnotation) })
            .filter({ $0.index >= idx })
    }

    func addAnnotation(for station: MutableStation, at idx: Int) {
        guard let position = station.position.value else {
            return
        }
        let distanceString = POIViewModel.distanceString(self.point.producer.ignoreNil().map({ ($0, position) }))
        let annotation = POIStationAnnotation(station: station,
                                              locatedAt: position,
                                              index: idx,
                                              distance: distanceString)
        annotations(from: idx).forEach { $0.index += 1 }
        map.addAnnotation(annotation)
    }

    func deleteAnnotations(for station: MutableStation) {
        let annotations = self.annotations(for: station)
        let idx = annotations.min(by: { $0.index < $1.index }).map({ $0.index })!
        map.removeAnnotations(annotations)
        self.annotations(from: idx+1).forEach { $0.index -= 1 }
    }

    func reorderAnnotations(withIndex fi: Int, to ti: Int) {
        if fi < ti {
            self.annotations(within: fi...ti).forEach { annotation in
                switch annotation.index {
                case fi: annotation.index = ti
                case _:  annotation.index -= 1
                }
            }
        } else {
            self.annotations(within: ti...fi).forEach { annotation in
                switch annotation.index {
                case fi: annotation.index = ti
                case _:  annotation.index += 1
                }
            }
        }
    }

    func apply(operations ops: [POIViewModel.Op]) {
        ops.forEach { op in
            switch op {
            case let .addStation(station, index: idx):
                self.addAnnotation(for: station, at: idx)
            case let .deleteStation(station, at: _):
                self.deleteAnnotations(for: station)
            case let .reorderStation(_, from: fi, to: ti):
                self.reorderAnnotations(withIndex: fi, to: ti)
            default: return
            }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Make the navigation bar fully transparent.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        }

        // Search for nearby stations.
        disposable += NearbyStationsViewModel.chain(connection, producer:
            combineLatest(point.producer.ignoreNil(), zoom.producer)
            .logEvents(identifier: "NearbyStationsViewModel.chain input", logger: logSignalEvent))
            .startWithResult() { result in
                switch result {
                case let .success(stations):    self.stations.swap(stations)
                case let .failure(error):       self.displayError(error)
                }
            }

        // Using location, update the map.
        disposable += location.startWithResult { result in
            switch result {
            case let .success(point, name, userLocation):
                self.point.swap(point)
                self.navigationItem.title = name
                self.updateMap(center: point, isUserLocation: userLocation)
            case let .failure(error):
                self.displayError(error)
            }
        }

        // Show nearby stations on the map.
        disposable += POIViewModel.chain(connection, producer: stations.producer).startWithResult({ result in
            switch result {
            case let .failure(error):
                self.displayError(error)
            case let .success(ops):
                self.apply(operations: ops)
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Reset the navigation bar.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(nil, for: UIBarMetrics.default)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposable.dispose()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "embedPOITable":
            let dest = segue.destination as! POITableViewController
            table = dest
            dest.stations = AnyProperty(stations)
            dest.mapPoint = point.producer.ignoreNil()
        case "showStation":
            let station = sender as! MutableStation
            let dest = segue.destination as! StationViewController
            dest.station = station
        default:
            return
        }
    }
}


// MARK: - Map view delegate
extension POIViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? POIStationAnnotation {
            let view =
                mapView.dequeueReusableAnnotationView(withIdentifier: "stationAnnotation") as? POIStationAnnotationView
                    ?? POIStationAnnotationView(annotation: annotation, reuseIdentifier: "stationAnnotation")
            view.apply(annotation)
            return view
        }

        // Returning nil causes the map to use a default annotation.
        return nil
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor.skyBlueColor().withAlphaComponent(0.1)
        return renderer
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let station = ((view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation)?.station {
            self.performSegue(withIdentifier: "showStation", sender: station)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = (view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation,
            let table = table
        {
            let section = table.dataSource.index(of: annotation.station)
            let row = (table.dataSource.arrivals[section].isEmpty) ? NSNotFound : 0
            table.tableView.scrollToRow(at: IndexPath(row: row, section: section), at: .top,
                                                   animated: true)
        }
    }
}
