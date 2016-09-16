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
import ReactiveCocoa
import Result
import Argo

class StationViewController: UIViewController, ProperViewController, ArrivalsTableViewDelegate {
    
    // MARK: Force-unwrapped properties
    var station: MutableStation!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nav: UINavigationItem!

    // MARK: Internal properties
    internal lazy var connection: ConnectionType = Connection.sharedInstance
    internal let disposable = CompositeDisposable()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar's title to the name of the stop.
        station.name.map { self.nav.title = $0 }

        // Configure the map once a point is available.
        station.position.map { point in
            guard let point = point else { return }
            self.map.region = MKCoordinateRegion.init(center: CLLocationCoordinate2D(point: point),
                span: MKCoordinateSpanMake(0.01, 0.01))
        }

        // As soon as we have a set of coordinates for the station's position, add it to the map.
        station.position.producer.ignoreNil().take(1).startWithNext { point in
            self.map.addAnnotation(MutableStation.Annotation(from: self.station, at: point))
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Subscribe to station updates.
        disposable += station.producer.startWithFailed(self.displayError)
    }

    override func viewWillDisappear(animated: Bool) {
        disposable.dispose()
        super.viewWillDisappear(animated)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier ?? "" {
        case "embedArrivalsTable":
            let table = segue.destinationViewController as! ArrivalsTableViewController
            table.station = station
            table.delegate = self
        case "embedRoutesCollection":
            let collection = segue.destinationViewController as! RoutesCollectionViewController
            collection.station = station
        default:
            return
        }
    }

    // MARK: Delegate methods
    func mutableModel<M: MutableModel>(model: M, receivedError error: ProperError) {
        self.displayError(error)
    }

    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath) {
        // transition to vehicle view
    }

    func arrivalsTable(receivedError error: ProperError) {
        self.displayError(error)
    }

}

