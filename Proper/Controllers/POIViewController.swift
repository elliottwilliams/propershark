//
//  POIViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate, MKMapViewDelegate {

    lazy var point = MutableProperty<Point?>(nil)
    lazy var viewModel: NearbyStationsViewModel = {
        return NearbyStationsViewModel(point: self.point, connection: self.connection)
    }()
    let location = Location.producer
    let annotation = MKPointAnnotation()

    @IBOutlet weak var map: MKMapView!

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    func configureMap(coordinate: CLLocationCoordinate2D, isUserLocation: Bool) {
        map.setCenterCoordinate(coordinate, animated: true)
        map.delegate = self

        let boundingRegion = MKCoordinateRegionMakeWithDistance(coordinate, NearbyStationsViewModel.searchRadius,
                                                                NearbyStationsViewModel.searchRadius)
        map.setRegion(map.regionThatFits(boundingRegion), animated: true)

        // DEBUG - show search area around point
        let circle = MKCircle(centerCoordinate: coordinate, radius: NearbyStationsViewModel.searchRadius)
        map.addOverlay(circle)

        if isUserLocation {
            map.showsUserLocation = true
        } else {
            // TODO - Move one annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            map.addAnnotation(annotation)
        }
    }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Make the navigation bar fully transparent.
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }

        // Subscribe to and follow location changes.
        disposable += location.startWithResult { result in
            switch result {
            case .Success(let location):
                let coordinate = location?.coordinate
                self.point.swap(coordinate.map({ Point(coordinate: $0) }))
            case .Failure(let error):
                self.displayError(error)
            }
        }

        // Bind changes in the POI point to map movements.
        disposable += point.producer.ignoreNil().startWithNext {
            self.configureMap(CLLocationCoordinate2D(point: $0), isUserLocation: true)
        }

        disposable += viewModel.stations.producer.map({ stations in
            stations.flatMap({ POIStationAnnotation(station: $0, badge: self.viewModel.badges[$0]!,
                distance: self.viewModel.distances[$0]!) })
        }).combinePrevious([]).startWithNext({ prev, next in
            self.map.removeAnnotations(prev)
            self.map.addAnnotations(next)
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
            dest.viewModel = viewModel
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

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let station = ((view as? POIStationAnnotationView)?.annotation as? POIStationAnnotation)?.station {
            performSegueWithIdentifier("showStation", sender: station)
        }
    }
}
