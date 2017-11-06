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
  fileprivate var diffCalculator: TableViewDiffCalculator<MutableStation, ArrivalState>
  let config: ConfigSP

  fileprivate let tableView: UITableView
  private let disposable = ScopedDisposable(CompositeDisposable())
  private let fetchScheduler = QueueScheduler(qos: .userInitiated, name: "POITableDataSource.fetchScheduler")
  private let defaultArrivals = Array(repeating: ArrivalState.loading, count: 1)

  fileprivate var slice: Property<ArraySlice<MutableStation>>
  fileprivate let limit = MutableProperty(30)

  init(tableView: UITableView, stations: Property<[MutableStation]>, config: ConfigSP) {
    self.tableView = tableView
    self.stations = stations
    self.config = config

    slice = stations.combineLatest(with: limit).map({ stations, limit in stations.prefix(limit) })
    diffCalculator = .init(tableView: tableView)
    diffCalculator.insertionAnimation = .fade
    diffCalculator.deletionAnimation = .fade
    super.init()

    disposable += slice.producer.startWithValues { [weak self] stations in
      let shouldAnimate = tableView.numberOfSections != 0 || stations.isEmpty
      // Populate the table with nearby stations.
      self?.update(withStations: stations, animated: shouldAnimate)
    }
  }

  func fetchArrivals(for station: MutableStation) -> SignalProducer<[Arrival], ProperError> {
    // Query Timetable and update the table with its response
    func call() -> SignalProducer<[Arrival], ProperError> {
      return Timetable.visits(for: station,
                              occurring: .between(Date(), Date(timeIntervalSinceNow: 3600)),
                              using: config)
        .on(value: { [weak self] arrivals in
          self?.update(section: station, with: arrivals)
        })
    }
    return SignalProducer { observer, disposable in
      // Starting now and every 30 seconds, call timetable.
      disposable += self.fetchScheduler.schedule(after: Date(), interval: .seconds(30)) {
        disposable += call().start(observer)
      }
    }
  }

  func populateArrivals(for station: MutableStation) {
    fetchArrivals(for: station).startWithResult { result in
      switch result {
      case .failure(_): break
      case .success(let arrivals): self.update(section: station, with: arrivals)
      }
    }
  }

  func loadMore() {
    limit.modify({ limit in limit += 30 })
  }

  private func update(section: MutableStation, with newArrivals: [Arrival]) {
    let wrappedArrivals = newArrivals.isEmpty ? [ArrivalState.none] : newArrivals.map({ ArrivalState.loaded($0) })
    let replacement = diffCalculator.sectionedValues.sectionsAndValues.map({ station, currentArrivals in
      (station, station == section ? wrappedArrivals : currentArrivals)
    })
    
    diffCalculator.sectionedValues = SectionedValues(replacement)
  }

  private func update<S: Sequence>(withStations stations: S, animated: Bool) where S.Element == MutableStation {
    let knownArrivals = diffCalculator.sectionedValues.sectionsAndValues.reduce(into: [String: [ArrivalState]]()) { (dict, tuple) in
      let (station, arrivals) = tuple
      dict[station.identifier] = arrivals
    }
    let replacement = stations.map({ station in
      (station, knownArrivals[station.identifier] ?? defaultArrivals)
    })

    if animated {
      diffCalculator.sectionedValues = SectionedValues(replacement)
    } else {
      UITableView.performWithoutAnimation {
        diffCalculator.sectionedValues = SectionedValues(replacement)
      }
    }
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

  func arrival(at indexPath: IndexPath) -> Arrival? {
    return diffCalculator.value(atIndexPath: indexPath).arrival
  }

  func arrivals(atSection index: Int) -> [Arrival] {
    let (_, arrivals) = diffCalculator.sectionedValues.sectionsAndValues[index]
    return arrivals.flatMap({ $0.arrival })
  }
}

// MARK: UITableViewDataSource
extension POITableDataSource: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return diffCalculator.numberOfSections()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return diffCalculator.numberOfObjects(inSection: section)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch diffCalculator.value(atIndexPath: indexPath) {
    case .loaded(let arrival):
      let cell = tableView.dequeueReusableCell(withIdentifier: "arrivalCell") as! ArrivalTableViewCell
      let route = station(at: indexPath.section).routes.producer.map({ routes in
        routes.first(where: { $0 == arrival.route })
      }).skipNil()
      cell.apply(arrival: arrival, route: route)
      return cell
    case .loading:
      populateArrivals(for: station(at: indexPath.section))
      let cell = tableView.dequeueReusableCell(withIdentifier: "loading")!
      let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      activityIndicator.startAnimating()
      cell.accessoryView = activityIndicator
      return cell
    case .none:
      let cell = tableView.dequeueReusableCell(withIdentifier: "none")!
      cell.textLabel?.text = "No upcoming departures."
      return cell
    }
  }
}

private enum ArrivalState: Equatable {
  case loaded(Arrival)
  case loading
  case none

  var arrival: Arrival? {
    switch self {
    case .loaded(let arrival): return arrival
    default:                   return nil
    }
  }

  static func == (a: ArrivalState, b: ArrivalState) -> Bool {
    switch (a, b) {
    case (.loaded(let a), .loaded(let b)): return a == b
    case (.loading, .loading): return true
    case (.none, .none):       return true
    default: return false
    }
  }
}
