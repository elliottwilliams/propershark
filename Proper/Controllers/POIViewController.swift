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

    var point: MutableProperty<Point> = .init(Point(lat: 40.4247277, long: -86.9114585)) // PMU
    lazy var viewModel: NearbyStationsViewModel = {
        return NearbyStationsViewModel(point: self.point, connection: self.connection)
    }()

    @IBOutlet weak var map: MKMapView!

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    func configureMap(centerPoint: Point) {
        let centerLoc = CLLocationCoordinate2D(point: centerPoint)
        map.centerCoordinate = centerLoc
        map.region = MKCoordinateRegion(center: centerLoc,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.delegate = self


        // DEBUG - show search area around point
        let circle = MKCircle(centerCoordinate: centerLoc, radius: NearbyStationsViewModel.searchRadius)
        map.addOverlay(circle)


        // TODO - Only show this point if we're not tracking the user's location.
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(point: centerPoint)
        map.addAnnotation(annotation)
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

        // Bind changes in the POI point to map movements.
        disposable += point.producer.startWithNext { self.configureMap($0) }

        disposable += viewModel.letteredStations.producer.map { stations in
            return stations.flatMap({ idx, station in POIStationAnnotation(station: station, annotationKey: idx) })
        }.combinePrevious([]).startWithNext({ prev, next in
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
        default:
            return
        }
    }

    // MARK: Map view delegate

//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        if let annotation = annotation as? POIStationAnnotation {
//            let view = mapView.dequeueReusableAnnotationViewWithIdentifier("stationAnnotation") ??
//                POIStationAnnotationView(annotation: annotation, reuseIdentifier: "stationAnnotation")
//            return view
//        }
//
//        // Returning nil causes the map to use a default annotation.
//        return nil
//    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKCircleRenderer(overlay: overlay)
        renderer.fillColor = UIColor.blueColor().colorWithAlphaComponent(0.3)
        return renderer
    }
}
