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

    var point: NamedPoint!

    @IBOutlet weak var map: MKMapView!

    internal var connection: ConnectionType = Connection.sharedInstance
    internal var disposable = CompositeDisposable()

    func configureMap(centerPoint: Point) {
        let centerLoc = CLLocationCoordinate2D(point: centerPoint)
        map.centerCoordinate = centerLoc
        map.region = MKCoordinateRegion(center: centerLoc,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        // Make the navigation bar fully transparent
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        // Reset the navigation bar
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// TODO: Move to model file
struct NamedPoint {
    let point: Point
    let title: String?
}
