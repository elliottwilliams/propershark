//
//  POIViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveCocoa

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate {

    var point: MutableProperty<Point> = .init(Point(lat: 40.4247277, long: -86.9114585)) // PMU
    var viewModel: NearbyStationsViewModel!

    @IBOutlet weak var map: MKMapView!

    internal var connection: ConnectionType = Connection.cachedInstance
    internal var disposable = CompositeDisposable()

    func configureMap(centerPoint: Point) {
        let centerLoc = CLLocationCoordinate2D(point: centerPoint)
        map.centerCoordinate = centerLoc
        map.region = MKCoordinateRegion(center: centerLoc,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(point: centerPoint)
        map.addAnnotation(annotation)
    }

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
            dest.point = AnyProperty(point)
        default:
            return
        }
    }
}

// TODO: Move to model file
struct NamedPoint {
    let point: Point
    let title: String?
}
