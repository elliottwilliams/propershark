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
import Dwifft

class POITableViewController: UITableViewController, ProperViewController {
  typealias Distance = CLLocationDistance
  static let headerViewHeight = CGFloat(55)

  var mapPoint: Property<Point>
  var connection: ConnectionType = Connection.cachedInstance
  var disposable = CompositeDisposable()

  fileprivate var headerDisposables: [UIView: Disposable] = [:]
  fileprivate var headerBadges: [UIView: Badge] = [:]
  fileprivate let stations: Property<[MutableStation]>

  lazy var dataSource: POITableDataSource = {
    return POITableDataSource(tableView: self.tableView, stations: Property(self.stations), connection: self.connection)
  }()

  init(style: UITableViewStyle, stations: Property<[MutableStation]>, mapPoint: Property<Point>) {
    self.mapPoint = mapPoint
    self.stations = stations
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

  func scroll(to station: MutableStation) {
    guard let index = dataSource.index(of: station) else {
      return
    }
    let row = dataSource.arrivals(atSection: index).isEmpty ? NSNotFound : 0
    tableView.scrollToRow(at: IndexPath(row: row, section: index), at: .top, animated: true)
  }

  fileprivate func resetBadgeIndices(startingFrom start: Int) {
    for idx in stride(from: start, to: tableView.numberOfSections, by: 1) {
      guard let view = tableView.headerView(forSection: idx) else {
        continue
      }
      headerBadges[view]?.set(numericalIndex: idx)
    }
  }
}

// MARK: Lifecycle
extension POITableViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewDidDisappear(_ animated: Bool) {
    disposable.dispose()
    disposable = .init()
    super.viewDidDisappear(animated)
  }
}

// MARK: Table View Delegate
extension POITableViewController {
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
    let station = dataSource.station(at: section)
    let badge = Badge(alphabetIndex: section, seedForColor: station)
    let position = station.position.producer.skipNil()
    let distance = POIViewModel.distanceString(mapPoint.producer.combineLatest(with: position))

    header.apply(station: station, badge: badge, distance: distance)

    headerBadges[header] = badge
    return header
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return POITableViewController.headerViewHeight
  }

  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    resetBadgeIndices(startingFrom: section+1)
    let station = dataSource.station(at: section)
    let disposable = dataSource.fetchArrivals(for: station).startWithFailed(displayError(_:))
    headerDisposables[view] = disposable
  }

  override func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
    headerBadges[view] = nil
    resetBadgeIndices(startingFrom: section+1)
    headerDisposables.removeValue(forKey: view)?.dispose()
  }
}
