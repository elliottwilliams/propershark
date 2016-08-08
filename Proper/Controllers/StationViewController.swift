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
    @IBOutlet weak var arrivalTableView: UITableView!

    // MARK: Internal properties
    internal lazy var connection: ConnectionType = Connection.sharedInstance
    internal lazy var config = Config.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // Subscribe to station updates.
        station.producer.startWithNext(station.apply)
        
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
        
        // Initialize and embed the arrivals table.
        let table = ArrivalsTableViewController(observing: station, delegate: self, style: arrivalTableView.style,
                                                connection: self.connection, config: self.config)
        table.view = arrivalTableView
        table.viewDidLoad()
        arrivalTableView.dataSource = table
        arrivalTableView.delegate = table

        table.willMoveToParentViewController(self)
        self.addChildViewController(table)
        table.didMoveToParentViewController(self)
    }

    // MARK: Delegate methods
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError) {
        self.displayError(error)
    }

    func arrivalsTable(selectedVehicle vehicle: MutableVehicle, indexPath: NSIndexPath) {
        // transition to vehicle view
    }

    func arrivalsTable(receivedError error: PSError) {
        self.displayError(error)
    }

#if false
    func showUserLocationIfEnabled() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.locationManager?.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        map.showsUserLocation = (status == CLAuthorizationStatus.AuthorizedAlways ||
                                 status == CLAuthorizationStatus.AuthorizedWhenInUse)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }
#endif

}

