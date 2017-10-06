//
//  POITableDataSource2.swift
//  Proper
//
//  Created by Elliott Williams on 10/1/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import Dwifft

class POITableDataSource: NSObject {
  let stations: Property<[MutableStation]>
  let diffCalculator: TableViewDiffCalculator<MutableStation, Arrival>
  let connection: ConnectionType

  fileprivate let tableView: UITableView
  private let disposable = ScopedDisposable(CompositeDisposable())
  private let fetchScheduler = QueueScheduler(qos: .userInitiated, name: "POITableDataSource.fetchScheduler")

  init(tableView: UITableView, stations: Property<[MutableStation]>, connection: ConnectionType) {
    self.tableView = tableView
    self.stations = stations
    self.diffCalculator = .init(tableView: tableView)
    self.connection = connection
    super.init()

    disposable += stations.producer.startWithValues { [weak self] stations in
      // Populate the table with nearby stations.
      self?.update(withStations: stations)
    }
  }

  func fetchArrivals(for station: MutableStation) -> SignalProducer<[Arrival], ProperError> {
    // Query Timetable and update the table with its response
    let call = Timetable.visits(for: station,
                                occurring: .between(Date(), Date(timeIntervalSinceNow: 3600)),
                                using: connection)
      .on(value: { [weak self] arrivals in
        self?.update(section: station, with: arrivals)
      })
    let delayedCall = SignalProducer<[Arrival], ProperError>.empty.delay(0.1, on: fetchScheduler).then(call)
    // A producer that completes when the _first_ arrival departs (and we need to reload data):
    let callUntilDeparture = delayedCall
      .flatMap(.latest, transform: { arrivals in arrivals.first?.lifecycle.map({ (arrivals, $0) }) ?? .never })
      .map({ arrivals, _ in arrivals })
    // A producer that lazily calls `fetchArrivals`:
    let fetch = SignalProducer<[Arrival], ProperError> { [weak self] observer, disposable in
      // Once self is released, this producer completes.
      disposable += self?.fetchArrivals(for: station).start(observer) ?? SignalProducer.empty.start(observer)
    }
    return callUntilDeparture.then(fetch)
  }

  private func update(section: MutableStation, with newArrivals: [Arrival]) {
    let replacement = diffCalculator.sectionedValues.sectionsAndValues.map({ station, arrivals -> (MutableStation, [Arrival]) in
      if station == section {
        return (station, newArrivals)
      } else {
        return (station, arrivals)
      }
    })
    
    diffCalculator.sectionedValues = SectionedValues(replacement)
  }

  private func update(withStations stations: [MutableStation]) {
    let knownArrivals: [MutableStation: [Arrival]] = diffCalculator.sectionedValues.sectionsAndValues.reduce(into: [:]) { (dict, tuple) in
      let (station, arrivals) = tuple
      dict[station] = arrivals
    }
    let replacement = stations.map({ station in (station, knownArrivals[station] ?? []) })
    diffCalculator.sectionedValues = SectionedValues(replacement)
    for idx in stations.indices {
      colorHeader(at: idx, with: ColorBrewer.purpleRed)
    }
  }

  private func colorHeader(at idx: Int, with scheme: ColorBrewer) {
    guard let header = tableView.headerView(forSection: idx) as? POIStationHeaderFooterView else {
      return
    }
    header.color = colorForHeader(at: idx, with: scheme)
  }

  func colorForHeader(at idx: Int, with scheme: ColorBrewer) -> UIColor {
    let idx = CGFloat(idx)
    let n = CGFloat(numberOfSections(in: tableView))
    return scheme.interpolatedColor(at: CGFloat(1).nextDown - (idx / n))
  }
}

// MARK: Data access
extension POITableDataSource {
  func station(at sectionIndex: Int) -> MutableStation {
    return diffCalculator.value(forSection: sectionIndex)
  }

  func index(of section: MutableStation) -> Int? {
    return diffCalculator.sectionedValues.sectionsAndValues.index(where: { station, _ in station == section })
  }

  func arrival(at indexPath: IndexPath) -> Arrival {
    return diffCalculator.value(atIndexPath: indexPath)
  }

  func arrivals(atSection index: Int) -> [Arrival] {
    let (_, arrivals) =  diffCalculator.sectionedValues.sectionsAndValues[index]
    return arrivals
  }
}

// MARK: UITableViewDataSource
extension POITableDataSource: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return stations.value.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return diffCalculator.numberOfObjects(inSection: section)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "arrivalCell") as! ArrivalTableViewCell
    let arrival = diffCalculator.value(atIndexPath: indexPath)
    cell.apply(arrival: arrival)
    return cell
  }
}
