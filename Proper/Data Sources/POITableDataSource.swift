//
//  POITableDataSource.swift
//  Proper
//
//  Created by Elliott Williams on 3/19/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import UIKit
import MapKit

class POITableDataSource: NSObject, UITableViewDataSource {
    typealias Distance = CLLocationDistance
    typealias Tuple = (station: MutableStation, badge: Badge, arrivals: [Arrival])

    var table: [(station: MutableStation, badge: Badge, arrivals: [Arrival])] = []
    var indices: [MutableStation: Int] = [:]

    // MARK: Accessors

    var stations: [MutableStation] {
        return table.lazy.map({ st, _, _ in st })
    }
    var arrivals: [[Arrival]] {
        return table.lazy.map({ _, _, ar in ar })
    }
    var badges: [Badge] {
        return table.lazy.map({ _, bd, _ in bd })
    }

    func indexOf(station: MutableStation) -> Int {
        return indices[station]!
    }

    // MARK: Mutators

    /// Update the `indices` map and badge for each station beginning at the `from` position.
    func updateIndices(from start: Int) {
        let offset = table.suffixFrom(start).enumerate().map({ i, tt in (i+start, tt) })
        offset.forEach(updateIndices)
    }

    /// Update the `indices` map and badge to match the table entry at the given `idx`.
    func updateIndices(at idx: Int) {
        updateIndices(at: idx, entry: table[idx])
    }
    private func updateIndices(at idx: Int, entry: Tuple) {
        let (station, badge, _) = entry
        indices[station] = idx
        badge.setIndex(idx)
    }

    func insert(entry: Tuple, atIndex idx: Int) {
        let (station, badge, arrivals) = entry
        table.insert((station, badge, arrivals), atIndex: idx)
        indices[station] = idx
        updateIndices(from: idx+1)
    }

    func indexPathForInserting(arrival: Arrival, onto station: MutableStation) -> NSIndexPath {
        let si = indexOf(station)
        let ri = arrivals[si].indexOf({ arrival < $0 }) ?? arrivals[si].endIndex
        table[si].arrivals.insert(arrival, atIndex: ri)
        return NSIndexPath(forRow: ri, inSection: si)
    }

    func indexPathForDeleting(arrival: Arrival, from station: MutableStation) -> NSIndexPath {
        let si = indexOf(station)
        let ri = arrivals[si].indexOf(arrival)!
        table[si].arrivals.removeAtIndex(ri)
        return NSIndexPath(forRow: ri, inSection: si)
    }

    func removeAtIndex(idx: Int) {
        table.removeAtIndex(idx)
        indices[stations[idx]] = nil
        updateIndices(from: idx)
    }

    func indexForRemoving(station: MutableStation) -> Int {
        let idx = indexOf(station)
        removeAtIndex(idx)
        return idx
    }

    // MARK: Table View Data Source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return stations.count
    }

    // Return the number of arrivals for each route on the each station of the section given.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrivals[section].count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("arrivalCell") as! ArrivalTableViewCell
        cell.contentView.layoutMargins.left = 40

        //let station = stations.value[indexPath.section]
        let arrival = arrivals[indexPath.section][indexPath.row]
        // TODO - Apply route and arrival information to the view
        cell.apply(arrival)
        return cell
    }
}
