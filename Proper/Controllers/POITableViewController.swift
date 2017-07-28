//
//  POITableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/15/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import Curry
import CoreLocation

class POITableViewController: UITableViewController, ProperViewController {
  typealias Distance = CLLocationDistance

  var mapPoint: Property<Point>
  let dataSource = POITableDataSource()

  internal var connection: ConnectionType = Connection.cachedInstance
  internal var disposable = CompositeDisposable()

  static let headerViewHeight = CGFloat(55)

  init(style: UITableViewStyle, mapPoint: Property<Point>) {
    self.mapPoint = mapPoint
    super.init(style: style)

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = dataSource
    tableView.register(UINib(nibName: "ArrivalTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "arrivalCell")
    tableView.register(UINib(nibName: "POIStationHeaderFooterView", bundle: nil),
                       forHeaderFooterViewReuseIdentifier: "stationHeader")
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Manipulates the table and data source with changes described by the table operations.
  func modifyTable(with ops: [POIViewModel.Op]) {
    // Iterate through `ops` and record changes made.
    var sectionInsertions = IndexSet()
    var sectionDeletions = IndexSet()
    var rowInsertions = [IndexPath]()
    var rowDeletions = [IndexPath]()

    tableView.beginUpdates()
    // Manipulate the data source for each operation.
    for op in ops {
      switch op {
      case let .addStation(station, index: idx):
        let badge = Badge(alphabetIndex: idx, seedForColor: station)
        dataSource.insert(entry: (station, badge, []), at: idx)
        sectionInsertions.insert(idx)

      case let .addArrival(arrival, to: station):
        let path = dataSource.indexPath(inserting: arrival, onto: station)
        rowInsertions.append(path)

      case let .deleteArrival(arrival, from: station):
        guard let si = dataSource.stations.index(of: station),
          dataSource.arrivals[si].index(of: arrival) != nil else {
            NSLog("WARN: .deleteArrival received for an arrival that doesn't exist 😕")
            continue
        }
        let path = dataSource.indexPath(deleting: arrival, from: station)
        rowDeletions.append(path)

      case let .deleteStation(station, at: idx):
        dataSource.remove(station: station)
        sectionDeletions.insert(idx)

      case let .reorderStation(_, from: fi, to: ti):
        dataSource.moveStation(from: fi, to: ti)
        tableView.moveSection(fi, toSection: ti)
      }
    }

    let deleted = sectionDeletions.subtracting(sectionInsertions)
    let inserted = sectionInsertions.subtracting(sectionDeletions)
    let reloaded = sectionDeletions.intersection(sectionInsertions)

    // Apply changes to the table.
    tableView.deleteRows(at: rowDeletions, with: .top)
    tableView.deleteSections(deleted, with: .automatic)
    tableView.insertSections(inserted, with: .automatic)
    tableView.reloadSections(reloaded, with: .automatic)
    tableView.insertRows(at: rowInsertions, with: .bottom)
    tableView.endUpdates()
  }

  // MARK: Lifecycle

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidDisappear(_ animated: Bool) {
    disposable.dispose()
    disposable = .init()
    super.viewDidDisappear(animated)
  }

  // MARK: Table View Delegate
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return POIViewModel.arrivalRowHeight
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // TODO - show vehicle details upon selection
    // In the meantime, we could segue to the station, but for now let's just do nothing.
//    parent?.performSegue(withIdentifier: "showStation", sender: dataSource.stations[indexPath.section])
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "stationHeader")
      as! POIStationHeaderFooterView
    let (station, badge, _) = dataSource.table[section]
    let position = station.position.producer.skipNil()
    let distance = POIViewModel.distanceString(mapPoint.producer.combineLatest(with: position))

    header.apply(station: station, badge: badge, distance: distance)
    return header
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return POITableViewController.headerViewHeight
  }
}
