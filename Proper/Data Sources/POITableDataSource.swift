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

  func index(of station: MutableStation) -> Int {
    return indices[station]!
  }

  // MARK: Mutators

  /// Update the `indices` map and badge for each station beginning at the `from` position.
  func updateIndices(from start: Int) {
    let offset = table.suffix(from: start).enumerated().map({ i, tt in (i+start, tt) })
    offset.forEach(updateIndices)
  }

  /// Update the `indices` map and badge to match the table entry at the given `idx`.
  func updateIndices(at idx: Int) {
    updateIndices(at: idx, entry: table[idx])
  }

  private func updateIndices(at idx: Int, entry: Tuple) {
    let (station, badge, _) = entry
    indices[station] = idx
    badge.set(numericalIndex: idx)
  }

  func insert(entry: Tuple, at idx: Int) {
    let (station, badge, arrivals) = entry
    table.insert((station, badge, arrivals), at: idx)
    indices[station] = idx
    updateIndices(from: idx+1)
  }

  func indexPath(inserting arrival: Arrival, onto station: MutableStation) -> IndexPath {
    let si = index(of: station)
    let ri = arrivals[si].index(where: { arrival < $0 }) ?? arrivals[si].endIndex
    table[si].arrivals.insert(arrival, at: ri)
    return IndexPath(row: ri, section: si)
  }

  func indexPath(deleting arrival: Arrival, from station: MutableStation) -> IndexPath {
    let si = index(of: station)
    let ri = arrivals[si].index(of: arrival)!
    table[si].arrivals.remove(at: ri)
    return IndexPath(row: ri, section: si)
  }

  func remove(station: MutableStation) {
    let idx = index(of: station)
    indices[stations[idx]] = nil
    table.remove(at: idx)
    updateIndices(from: idx)
  }

  func moveStation(from fi: Int, to ti: Int) {
    guard fi != ti else {
      return
    }

    let temp = table[fi]
    let dir = (ti-fi) / abs(ti-fi)
    stride(from: fi, to: ti, by: dir).forEach { i in
      table[i] = table[i+dir]
      updateIndices(at: i)
    }
    table[ti] = temp
    updateIndices(at: ti)
  }

  // MARK: Table View Data Source

  func numberOfSections(in tableView: UITableView) -> Int {
    return stations.count
  }

  // Return the number of arrivals for each route on the each station of the section given.
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return arrivals[section].count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
    -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCell(withIdentifier: "arrivalCell") as! ArrivalTableViewCell

    //let station = stations.value[indexPath.section]
    let arrival = arrivals[indexPath.section][indexPath.row]
    // TODO - Apply route and arrival information to the view
    cell.apply(arrival: arrival)
    return cell
  }
}
