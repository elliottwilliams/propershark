//
//  MutableStation.swift
//  Proper
//
//  Created by Elliott Williams on 7/10/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa

struct MutableStation: MutableModel {
    typealias FromModel = Station
    
    let stop_code: FromModel.Identifier
    var identifier: FromModel.Identifier { return self.stop_code }
    
    let code: MutableProperty<String?>
    let name: MutableProperty<String>
    let description: MutableProperty<String?>
    let position: MutableProperty<Point?>
    
    init(from station: Station) {
        self.code = .init(station.code)
        self.name = .init(station.name)
        self.stop_code = station.stop_code
        self.description = .init(station.description)
        self.position = .init(station.position)
    }
    
    func apply(station: Station) throws {
        if station.identifier != self.identifier {
            throw PSError(code: .mutableModelFailedApply)
        }
        
        self.code <- station.code
        self.name <- station.name
        self.description <- station.description
        self.position <- station.position
    }
    
}