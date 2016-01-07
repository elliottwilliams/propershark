//
//  Station.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/27/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import Foundation
import MapKit

struct Station: Hashable {
    let name: String
    let id: String
    let neighborhood: [String]?
    let location: (latitude: Double, longitude: Double)
    
    var hashValue: Int { return id.hashValue }
}

func ==(a: Station, b: Station) -> Bool {
    return a.id == b.id
}

extension Station {
    func viewModel() -> StationViewModel {
        return StationViewModel(self)
    }
    
    static let DemoStations = [
        Station(name: "Beering Hall", id: "BUS001", neighborhood: [], location: (40.425618, -86.916668)),
        Station(name: "Purdue Memorial Union", id: "BUS123", neighborhood: [], location: (40.4246641, -86.9115902)),
        Station(name: "Electrical Engineering", id: "BUS456", neighborhood: [],
            location: (40.4284618, -86.9116224)),
        Station(name: "Columbia & Northwestern", id: "BUS789", neighborhood: [],
            location: (40.4249377, -86.9083984))
    ]
}