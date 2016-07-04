//
//  SceneMediator.swift
//  Proper
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

// The scene mediator is used to pass data between view controllers before a segue is performed. By using the mediator instead of hard-coding the handoff in each controller's prepareForSegue method, view controllers don't have to be aware of each other, which would break the Open/Closed Principle.
class SceneMediator: NSObject, SceneMediatorProtocol {
    
    static let sharedInstance = SceneMediator()
    
    /* General rules for how we're using segues:
     * - All segues that need to be mediated have named identifiers.
     * - Identifiers are named according to the scheme (segue type + destination view + verb condition for segue + source view or scene)
     * - Mediators should try to avoid depending on class properties. Use set*Model methods.
     * - If a segue is triggered programmatically, its sender contains data to pass to the destination.
     */
    let _mediators: [String: (UIStoryboardSegue, AnyObject?) -> Void] = [
        
        "ShowVehicleAfterSelectionFromList": { (segue, sender) in
            let src = segue.sourceViewController as! StartListViewController
            let dest = segue.destinationViewController as! VehicleViewController
            let indexPath = src.tableView.indexPathForSelectedRow
            
            dest.vehicle = src.vehicles[indexPath!.row].viewModel()
        },
        
        "ShowStationAfterSelectionFromList": { (segue, sender) in
            let src = segue.sourceViewController as! StartListViewController
            let dest = segue.destinationViewController as! StationViewController
            let indexPath = src.tableView.indexPathForSelectedRow
            
            dest.station = src.stations[indexPath!.row].viewModel()
        },
        
        "ShowVehicleOnArrivalTableSelection": { (segue, sender) in
            let src = segue.sourceViewController as! ArrivalTableViewController
            let dest = segue.destinationViewController as! VehicleViewController
            let indexPath = src.tableView.indexPathForSelectedRow
            dest.vehicle = src._arrivals[indexPath!.row].vehicle
        },
        
        "ShowVehicleWhenSelectedFromStation": { (segue, sender) in
            let src = segue.sourceViewController as! StationViewController
            let dest = segue.destinationViewController as! VehicleViewController
            let arrival: ArrivalViewModel = decode(sender as! NSData)
            dest.vehicle = arrival.vehicle
        },
        
        "ShowRouteAfterSelectionFromList": { (segue, sender) in
            let src = segue.sourceViewController as! StartListViewController
            let dest = segue.destinationViewController as! RouteViewController
            let indexPath = src.tableView.indexPathForSelectedRow
            dest.route = src.routes[indexPath!.row].viewModel()
        },
        
        "ShowStationFromRouteTable": { (segue, sender) in
            let src = segue.sourceViewController as! RouteViewController
            let dest = segue.destinationViewController as! StationViewController
            
            // Sender is a station view model struct wrapped in an NSData object to keep objc happy.
            dest.station = decode(sender as! NSData)
        },
        
        "ShowVehicleFromRouteTable": { (segue, sender) in
            let src = segue.sourceViewController as! RouteViewController
            let dest = segue.destinationViewController as! VehicleViewController
            
            dest.vehicle = decode(sender as! NSData)
        }
    ]
    
    func sendMessagesForSegueWithIdentifier(identifier: String?, segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = identifier {

            // Look up the segue and perform its transition step
            let transition = _mediators[id]
            transition?(segue, sender)

            NSLog("transition mediated for \(id)")
        }
    }
    
}

// We pass swift structs into the mediator as NSData, since the segue infrastructure needs objc objects. This function allocates a pointer to memory of size for a given struct, then moves bytes from the NSData instance to that pointer. The last line deallocates the pointer and returns its typed contents.
private func decode<T>(data: NSData) -> T {
    let pointer = UnsafeMutablePointer<T>.alloc(sizeof(T))
    data.getBytes(pointer, length: sizeof(T))
    return pointer.move()
}

// The scene mediator behaves according to this protocol
protocol SceneMediatorProtocol {
    func sendMessagesForSegueWithIdentifier(identifier: String?, segue: UIStoryboardSegue, sender: AnyObject?)
}

// View controllers that use the scene mediator must conform to this protocol
protocol SceneMediatedController {
    var sceneMediator: SceneMediator! { get set }
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
}

// TODO: consider subclassing UIViewController into a base class that all PS view controller inherit from. This base class would do scene mediating.