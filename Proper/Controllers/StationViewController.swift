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

class StationViewController: UIViewController, ProperViewController/*, ArrivalTableViewDelegate*/, MutableModelDelegate {
    
    // MARK: Force-unwrapped properties
    var station: MutableStation!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var nav: UINavigationItem!
    @IBOutlet weak var arrivalTableView: UITableView!

    // MARK: Internal properties
    internal lazy var connection: ConnectionType = Connection.sharedInstance
    internal lazy var config = Config.sharedInstance

    // MARK: Signals
//    lazy var producer: SignalProducer<TopicEvent, PSError> = {
//
//        // Get the station immediately...
//        let meta = self.connection.call("meta.last_event", args: [self.station.topic, self.station.topic])
//            .map { TopicEvent.parseFromRPC("meta.last_event", event: $0) }
//
//        // ...and subscribe to updates on its topic
//        let future = self.connection.subscribe(self.station.topic)
//            .map { TopicEvent.parseFromTopic(self.station.topic, event: $0) }
//
//        // Combine these two signals into one, which will produce TopicEvents coming from either the RPC or the
//        // subscription.
//        return SignalProducer<SignalProducer<TopicEvent?, PSError>, PSError>(values: [meta, future])
//            .flatten(.Merge)
//            .unwrapOrFail { PSError(code: .parseFailure) }
//            .on(next: { event in self.handle(event)},
//                failed: self.displayError)
//            .logEvents(identifier: "StationViewController.producer", logger: logSignalEvent)
//    }()
//
//    private func handle(event: TopicEvent) -> Result<(), PSError> {
//        switch event {
//        case .Meta(.lastEvent(let args, _)):
//            guard let object = args.first, let station = decode(object) as Station?
//                else { return .Failure(PSError(code: .parseFailure)) }
//            return self.station.apply(station)
//
//        case .Station(.update(let object, _)):
//            guard let station = decode(object) as Station?
//                else { return .Failure(PSError(code: .parseFailure)) }
//            return self.station.apply(station)
//
//        default:
//            NSLog("unhandled topic event: \(event)")
//            // TODO: maybe this shouldn't be an error in production
//            return .Failure(PSError(code: .unhandledTopic))
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the navigation bar's title to the name of the stop
        station.name.map { self.nav.title = $0 }

        // Configure the map once a point is available
        station.position.map { point in
            guard let point = point else { return }
            self.map.region = MKCoordinateRegion.init(center: CLLocationCoordinate2D(point: point),
                span: MKCoordinateSpanMake(0.01, 0.01))
        }

        // As soon as we have a set of coordinates for the station's position, add it to the map
        station.position.producer.ignoreNil().take(1).startWithNext { point in
            self.map.addAnnotation(MutableStation.Annotation(from: self.station, at: point))
        }
        
        // Get arrivals and embed an arrivals table
//        self.embedArrivalsTable()
    }

    // MARK: Delegate methods
    func mutableModel<M: MutableModel>(model: M, receivedError error: PSError) {
        self.displayError(error)
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

