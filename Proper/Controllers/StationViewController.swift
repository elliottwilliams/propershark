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

@objc class StationViewController: UIViewController, ProperViewController/*, ArrivalTableViewDelegate*/ {
    
    // MARK: Force-unwrapped properties
    var station: MutableStation!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nav: UINavigationItem!
    @IBOutlet weak var arrivalTableView: UITableView!

    // MARK: Internal properties
    internal lazy var connection: ConnectionType = Connection.sharedInstance
    internal lazy var config = Config.sharedInstance

    // MARK: Signals
    lazy var producer: SignalProducer<TopicEvent, PSError> = {
        let meta = self.connection.call("meta.last_event", args: [self.station.topic])
            .map { TopicEvent.parseFromRPC("meta.last_event", event: $0) }

        let future = self.connection.subscribe(self.station.topic)
            .map { TopicEvent.parseFromTopic(self.station.topic, event: $0) }

        return SignalProducer<SignalProducer<TopicEvent?, PSError>, PSError>(values: [meta, future])
            .flatten(.Merge)
            .unwrapOrFail { PSError(code: .parseFailure) }
            .on(next: { event in self.handleTopicEvent(event)})
            .logEvents(identifier: "StationViewController.producer", logger: logSignalEvent)
    }()

    private func handleTopicEvent(event: TopicEvent) -> Result<(), PSError> {
        switch event {
        case .Meta(.lastEvent(let args, _)):
            guard let object = args.first, let station = decode(object) as Station?
                else { return .Failure(PSError(code: .parseFailure)) }
            return self.station.apply(station)

        case .Station(.update(let object, _)):
            guard let station = decode(object) as Station?
                else { return .Failure(PSError(code: .parseFailure)) }
            return self.station.apply(station)

        default:
            NSLog("unhandled topic event: \(event)")
            return .Failure(PSError(code: .unhandledTopic))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        producer.start()
        
        // Set the navigation bar's title to the name of the stop
        station.name.map { self.nav.title = $0 }

        // Configure the map
        station.position.map { point in
            self.map.region = MKCoordinateRegion.init(center: CLLocationCoordinate2D(point: point),
                span: MKCoordinateSpanMake(0.01, 0.01))
        }
        
        // Add the selected stop to the map
        map.addAnnotation(MutableStation.Annotation(from: station))
        // Get arrivals and embed an arrivals table
//        self.embedArrivalsTable()
    }

#if false
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

    
    // When a row is selected in the Arrivals table, show the Vehicle view. Conformance to ArrivalTableViewDelegate.
    /*
    func didSelectArrivalFromArrivalTable(var arrival: ArrivalViewModel, indexPath:

        // Store arrival in an NSData object to pass to the segue, since objc is allergic to swift structs
        withUnsafePointer(&arrival) { p in
            let data = NSData(bytes: p, length: sizeofValue(arrival))
            self.performSegueWithIdentifier("ShowVehicleWhenSelectedFromStation", sender: data)
        }
    }
     */

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }
#endif
}

