//
//  AppDelegate.swift
//  Proper
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit
import ReactiveCocoa
import MDWamp

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // self.locationManager = CLLocationManager()
        // Desired location accuracy can be set further, and maybe it should be if we are using location data for core application functionality. At this time it's just used to show a blue dot on the map, so as long as it's relatively close, we're cool.
        // self.locationManager?.delegate = PFLocationManagerDelegate() // TODO: determine if this is needed
        // self.locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // Register nibs
        
        // Playground tiem
        
        /*Connection.sharedInstance.call("meta.last_event", args: ["vehicles.4004", "vehicles.4004"]).startWithNext() { result in
            guard let args = result.arguments[safe: 0] as? [AnyObject],
                let evtArgs = args[safe: 0] as? [AnyObject],
                let evtKwargs = args[safe: 1] as? [NSObject: AnyObject]
                else { fatalError("bad last_event!") }
            
            let maybeEvent = TopicEvent.parseFromTopic("vehicles.4004", args: evtArgs, kwargs: evtKwargs)
            NSLog("event: \(maybeEvent ?? nil)")
            
            guard let event = maybeEvent,
                  case let .Vehicle(.update(object, (originator, eventName))) = event
                  else { return }
         
            NSLog("vehicles.4004's last event was an \(eventName) event originating from \(originator) that sent this object:")
            NSLog(object.description ?? "")
        }*/
        
        let topic = ModelRoute.topicFor("1A")
        Connection.sharedInstance.subscribe(topic)
        .map { wampEvent in TopicEvent.parseFromTopic(topic, event: wampEvent) }
        .ignoreNil()
        .startWithNext { event in
            NSLog("event: \(event)")
        }
        
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

