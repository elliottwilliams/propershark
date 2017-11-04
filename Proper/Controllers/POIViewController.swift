//
//  POIViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/13/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import MapKit
import CoreLocation

class POIViewController: UIViewController, ProperViewController, UISearchControllerDelegate {
  // MARK: Point properties
  typealias NamedPoint = POIViewModel.NamedPoint

  /// Map annotation for the point of interest represented by this view. Only used for static locations.
  let annotation = MKPointAnnotation()

  var tableController: POITableViewController!
  var mapController: POIMapViewController!

  /// The point tracked by the POI view. Its position triggers new searches and updated the map view. Its value is modified
  /// by the `location` producer, user interactions with the map, and agency config changes.
  lazy var point: MutableProperty<Point> = {
    let center = Config.shared.map({ Point(coordinate: $0.agency.region.center) })
    let property = MutableProperty(center.value)
    property <~ center
    return property
  }()

  /// The area represented by the map.
  lazy var zoom = MutableProperty<MKCoordinateSpan>(MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.15)) // Default zoom, city-wide

  lazy var isUserLocation = MutableProperty(true)

  // Stations found within the map area. This producer is passed to the POITableViewController and is a basis for its
  // view model.
  lazy var stations = MutableProperty<[MutableStation]>([])
  lazy var routes: Property<Set<MutableRoute>> = {
    let routes = self.stations.producer.map({ stations in
      Set(stations.flatMap(({ $0.routes.value })))
    })
    return Property(initial: Set(), then: routes)
  }()

  /// A producer for the device's location, which adds metadata used by the view into the signal. It is started when
  /// the view appears, but is interrupted if a static location is passed by `staticLocation`.
  let deviceLocation = Location.producer |> POIViewModel.distinctLocations

  /// A producer for a "static location" of the view. This static location overrides the device location and makes the
  /// view represent the latest point passed.
  var staticLocation = SignalProducer<NamedPoint, ProperError>.never

  /// A producer that merges `deviceLocation` and `staticLocation`. The device location will be used until
  /// `staticLocation` emits a `NamedPoint`, at which point the producer is replaced by `staticLocation`.
  var location: SignalProducer<NamedPoint, ProperError> {
    return deviceLocation.take(untilReplacement: staticLocation)
  }

  private let config: ConfigSP = Config.producer
  private let searchScheduler = QueueScheduler(qos: .userInitiated, name: "searchScheduler")

  // MARK: Conformances
  internal var disposable = CompositeDisposable()

  // MARK: Lifecycle

  private func loadMapController() {
    let onSelect: Action<MutableStation, (), NoError> = Action { [unowned self] station in
      self.tableController.scroll(to: station)
      return SignalProducer.empty
    }

    let mapController = POIMapViewController(center: point,
                                             zoom: zoom,
                                             routes: Property(routes),
                                             stations: Property(stations),
                                             onSelect: onSelect,
                                             isUserLocation: Property(isUserLocation))
    addChildViewController(mapController)
    view.addSubview(mapController.view)
    mapController.didMove(toParentViewController: self)
    self.mapController = mapController
  }

  private func loadTableController() {
    let tableController = POITableViewController(style: .plain, stations: Property(stations), mapPoint: Property(point), config: config)
    addChildViewController(tableController)
    view.addSubview(tableController.view)
    tableController.didMove(toParentViewController: self)
    self.tableController = tableController
  }

  private func installConstraints() {
    let map = mapController.view!
    let table = tableController.view!
    let guide = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      map.topAnchor.constraint(equalTo: view.topAnchor),
      map.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      map.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      map.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),

      table.topAnchor.constraint(equalTo: map.bottomAnchor),
      table.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      table.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
    ])
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    loadMapController()
    loadTableController()
    installConstraints()
  }

  func openAgencySelector() {
    let agencyTable = AgencyTableViewController(configurations: Config.knownConfigurations, configProperty: Config.shared)
    let navigationController = UINavigationController(rootViewController: agencyTable)
    present(navigationController, animated: true, completion: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)


    // Clear the title until the signals created in `viewWillAppear` set one.
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Agencies", style: .plain, target: self,
                                                       action: #selector(openAgencySelector))

    // Clear stations when the config changes.
    disposable += config.producer.startWithValues { _ in self.stations.swap([]) }

    let searchProducer = point.producer
      .observe(on: searchScheduler)
      .throttle(0.5, on: searchScheduler)
      .logEvents(identifier: "NearbyStationsViewModel searchProducer",
                 logger: logSignalEvent)

    // Search for nearby stations.
    disposable += NearbyStationsViewModel.search(config: Config.producer, searchParameters: searchProducer)
      .observe(on: UIScheduler())
      .startWithResult() { result in
        assert(Thread.isMainThread)
        switch result {
        case let .success(stations):    self.stations.swap(stations)
        case let .failure(error):       self.displayError(error)
        }
    }

    // Using location, update the map.
    disposable += location.startWithResult { result in
      switch result {
      case let .success(point, name, isUserLocation):
        if self.mapController.contains(point: point) {
          self.point.swap(point)
          self.navigationItem.title = name
        }
        self.isUserLocation.swap(isUserLocation)
      case let .failure(error):
        self.displayError(error)
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Reset the navigation bar.
    if let bar = navigationController?.navigationBar {
      bar.setBackgroundImage(nil, for: UIBarMetrics.default)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    disposable.dispose()
    disposable = CompositeDisposable()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier ?? "" {
    case "showStation":
      let station = sender as! MutableStation
      let dest = segue.destination as! StationViewController
      dest.station = station
    default:
      return
    }
  }
}
