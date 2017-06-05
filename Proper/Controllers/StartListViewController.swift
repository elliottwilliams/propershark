//
//  StartListViewController.swift
//  Proper
//
//  Created by Elliott Williams on 12/24/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import Argo

class StartListViewController: UITableViewController, ProperViewController {

  // MARK: Properties
  var routes: [Route] = []
  var stations: [Station] = []
  var vehicles: [Vehicle] = []

  internal lazy var connection: ConnectionType = Connection.cachedInstance
  internal let disposable = CompositeDisposable()
  private var routeDisposable: Disposable?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: Signals

  private lazy var routeSignal: SignalProducer<[Route], ProperError> = {
    return self.connection.call("agency.routes")
      .attemptMap { event -> Result<[AnyObject], ProperError> in
        guard case .agency(.routes(let routes)) = event else { return .failure(.eventParseFailure) }
        return .success(routes)
      }
      .decodeAnyAs(Route.self)
      .on(failed: self.displayError,
          value: { self.routes = $0; self.tableView.reloadData() })
  }()

  private lazy var stationSignal: SignalProducer<[Station], ProperError> = {
    return self.connection.call("agency.stations")
      .attemptMap { event -> Result<[AnyObject], ProperError> in
        guard case .agency(.stations(let stations)) = event else { return .failure(.eventParseFailure) }
        return .success(stations)
      }
      .decodeAnyAs(Station.self)
      .on(failed: self.displayError,
          value: { self.stations = $0; self.tableView.reloadData() })
  }()

  private lazy var vehicleSignal: SignalProducer<[Vehicle], ProperError> = {
    return self.connection.call("agency.vehicles")
      .attemptMap { event -> Result<[AnyObject], ProperError> in
        guard case .agency(.vehicles(let vehicles)) = event else { return .failure(.eventParseFailure) }
        return .success(vehicles)
      }
      .decodeAnyAs(Vehicle.self)
      .on(failed: self.displayError,
          value: { self.vehicles = $0; self.tableView.reloadData() })
  }()

  lazy var pinnedStations: Property<[Station]> = {
    let pinned = Set(["BUS313NE"])
    let producer = self.stationSignal.map { stations in
      stations.filter { pinned.contains($0.stopCode) }
      }.flatMapError { error in
        return SignalProducer<[Station], NoError>.empty
    }
    return Property(initial: [], then: producer)
  }()

  // MARK: View events

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Start signals to populate the list
    self.routeSignal.start()
    self.stationSignal.start()
    self.vehicleSignal.start()

    self.pinnedStations.producer.startWithValues { _ in
      self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
  }

  // MARK: - Table view data source

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return [pinnedStations.value.count, routes.count, vehicles.count, stations.count][section]
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return ["Pinned Stations", "Routes", "Vehicles", "Stations"][section]
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell? = nil

    switch (indexPath.section) {
    case 0:
      cell = tableView.dequeueReusableCell(withIdentifier: "PinnedStationPrototypeCell", for: indexPath)
      let station = pinnedStations.value[indexPath.row]
      cell!.textLabel?.text = station.name
    case 1:
      cell = tableView.dequeueReusableCell(withIdentifier: "RoutePrototypeCell", for: indexPath)
      let route = routes[indexPath.row]
      cell!.textLabel?.text = route.name
    case 2:
      cell = tableView.dequeueReusableCell(withIdentifier: "VehiclePrototypeCell", for: indexPath)
      let vehicle = vehicles[indexPath.row]
      cell!.textLabel?.text = vehicle.name
    case 3:
      cell = tableView.dequeueReusableCell(withIdentifier: "StationPrototypeCell", for: indexPath)
      let station = stations[indexPath.row]
      cell!.textLabel?.text = station.name
    default:
      cell = nil
    }

    return cell!
  }

  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    // A row must be selected to show the arrivals view
    if identifier == "ShowStationView" {
      let row = self.tableView.indexPathForSelectedRow
      return row != nil
    } else {
      return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let id = segue.identifier else { return }
    switch id {
    case "ShowPinnedStation":
      guard let dest = segue.destination as? StationViewController,
        let index = self.tableView.indexPathForSelectedRow
        else { break }
      let station = self.pinnedStations.value[index.row]
      dest.station = try! MutableStation(from: station, connection: Connection.cachedInstance)
    case "ShowStationAfterSelectionFromList":
      guard let dest = segue.destination as? StationViewController,
        let index = self.tableView.indexPathForSelectedRow
        else { break }
      let station = self.stations[index.row]
      dest.station = try! MutableStation(from: station, connection: Connection.cachedInstance)
    case "ShowRouteAfterSelectionFromList":
      let dest = segue.destination as! RouteViewController
      let index = self.tableView.indexPathForSelectedRow!
      let route = self.routes[index.row]
      dest.route = try! MutableRoute(from: route, connection: self.connection)
    default:
      break
    }
  }

}
