//
//  MutableStation.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result

struct MutableStation: MutableModel {
    typealias FromModel = Station
    
    let stop_code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.stop_code }
    var topic: String { return FromModel.topicFor(self.identifier) }
    
    let name: MutableProperty<String>
    let description: MutableProperty<String?>
    let position: MutableProperty<Point>
    
    init(from station: Station) {
        self.name = .init(station.name)
        self.stop_code = station.stop_code
        self.description = .init(station.description)
        self.position = .init(station.position)
    }
    
    func apply(station: Station) -> Result<(), PSError> {
        if station.identifier != self.identifier {
            return .Failure(PSError(code: .mutableModelFailedApply))
        }
        
        self.name <- station.name
        self.description <- station.description
        self.position <- station.position

        return .Success()
    }

    class Annotation: NSObject, MKAnnotation {
        @objc var coordinate: CLLocationCoordinate2D
        @objc var title: String?
        @objc var subtitle: String?

        init(from station: MutableStation) {
            self.coordinate = CLLocationCoordinate2D(point: station.position.value)
            super.init()

            // Bind future values to annotation properties:
            station.position.map { self.coordinate = CLLocationCoordinate2D(point: $0) }
            station.name.map { self.title = $0 }
            station.description.map { self.subtitle = $0 }
        }
    }
}