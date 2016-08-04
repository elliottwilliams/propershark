//
//  Models.swift
//  Proper
//
//  Created by Elliott Williams on 8/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import XCTest
import Argo
@testable import Proper

func rawModels() -> (station: AnyObject, route: AnyObject, vehicle: AnyObject) {
    let bundle = NSBundle(identifier: "ms.elliottwillia.ProperTests")!
    let stationPath = bundle.pathForResource("station", ofType: "json")!
    let stationData = NSData(contentsOfFile: stationPath)
    let station = try! NSJSONSerialization.JSONObjectWithData(stationData!, options: [])

    let routePath = bundle.pathForResource("route", ofType: "json")!
    let routeData = NSData(contentsOfFile: routePath)
    let route = try! NSJSONSerialization.JSONObjectWithData(routeData!, options: [])

    let vehiclePath = bundle.pathForResource("vehicle", ofType: "json")!
    let vehicleData = NSData(contentsOfFile: vehiclePath)
    let vehicle = try! NSJSONSerialization.JSONObjectWithData(vehicleData!, options: [])

    return (station, route, vehicle)
}

func decodedModels() -> (station: Station!, route: Route!, vehicle: Vehicle!) {
    let (station, route, vehicle) = rawModels()
    return (
        Station.decode(JSON(station)).value,
        Route.decode(JSON(route)).value,
        Vehicle.decode(JSON(vehicle)).value
    )
}