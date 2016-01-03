//
//  StationViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class StationViewController: UIViewController, SceneMediatedController, ArrivalTableViewDelegate {
    
    // MARK: Properties
    var station: StationViewModel!
    var _sceneMediator = SceneMediator.sharedInstance
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nav: TransitNavigationItem!
    @IBOutlet weak var arrivalTableView: UITableView!
    
    // MARK: Actions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar's title to the name of the stop
//        nav.title = station.name
        self.navigationItem.title = station.name
        
        // Configure the map
        map.region = MKCoordinateRegion(center: station.coordinate, span: MKCoordinateSpanMake(0.01, 0.01))
        showUserLocationIfEnabled()
        
        // Add the selected stop to the map
        map.addAnnotation(station)
        
        // Get arrivals and embed an arrivals table
        self.embedArrivalsTable()
    }
    
    func embedArrivalsTable() {
        let arrivals = station.arrivalsAtStation()

        // Create view control bound to the table view unpacked from the nib
        let arrivalTable = ArrivalTableViewController(title: "Arrivals", arrivals: arrivals, delegate: self, view: self.arrivalTableView)
        self.arrivalTableView.dataSource = arrivalTable
        self.arrivalTableView.delegate = arrivalTable
        
        // Establish a parent-child relationship between the station and the arrivals table
        arrivalTable.willMoveToParentViewController(self)
        self.addChildViewController(arrivalTable)
        arrivalTable.didMoveToParentViewController(self)
    }
    
    func showUserLocationIfEnabled() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        delegate.locationManager?.requestWhenInUseAuthorization()
        let status = CLLocationManager.authorizationStatus()
        map.showsUserLocation = (status == CLAuthorizationStatus.AuthorizedAlways ||
                                 status == CLAuthorizationStatus.AuthorizedWhenInUse)
    }
    
    // When a row is selected in the Arrivals table, show the Vehicle view. Conformance to ArrivalTableViewDelegate
    func didSelectArrivalFromArrivalTable(arrival: ArrivalViewModel, indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("ShowVehicleWhenSelectedFromStation", sender: arrival)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}

