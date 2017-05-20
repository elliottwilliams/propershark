//
//  StationViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ReactiveSwift
import Result
import Argo

class StationViewController: UIViewController, ProperViewController {
    
    // MARK: Force-unwrapped properties
    var station: MutableStation!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nav: UINavigationItem!

    // MARK: Internal properties
    internal lazy var connection: ConnectionType = Connection.cachedInstance
    internal let disposable = CompositeDisposable()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar's title to the name of the stop.
        disposable += station.name.producer.startWithValues({ self.nav.title = $0 })

        // Configure the map once a point is available.
        disposable += station.position.producer.skipNil().startWithValues({ point in
            self.map.region = MKCoordinateRegion.init(center: CLLocationCoordinate2D(point: point),
                span: MKCoordinateSpanMake(0.01, 0.01))
        })

        // As soon as we have a set of coordinates for the station's position, add it to the map.
        disposable += station.position.producer.skipNil().take(first: 1).startWithValues { point in
            self.map.addAnnotation(MutableStation.Annotation(from: self.station, at: point))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Subscribe to station updates.
        disposable += station.producer.startWithFailed(self.displayError)
    }

    override func viewWillDisappear(_ animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "embedArrivalsTable":
            let table = segue.destination as! ArrivalsTableViewController
            table.station = station
        default:
            return
        }
    }
}

