//
//  AgencyTableViewController.swift
//  Proper
//
//  Created by Elliott Williams on 10/5/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift

class AgencyTableViewController: UITableViewController {
  let configurations: [ConfigProtocol]
  let configProperty: MutableProperty<ConfigProtocol>

  init(configurations: [ConfigProtocol], configProperty: MutableProperty<ConfigProtocol>) {
    self.configurations = configurations
    self.configProperty = configProperty
    super.init(style: .grouped)

    tableView.register(DisposableCell.self, forCellReuseIdentifier: "cell")
    navigationItem.title = "Transit Agencies"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
  }

  @IBAction func done(_ sender: AnyObject) {
    dismiss(animated: true, completion: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private class DisposableCell: UITableViewCell {
  var disposable = ScopedDisposable(CompositeDisposable())
  override func prepareForReuse() {
    disposable = ScopedDisposable(CompositeDisposable())
  }
}

extension AgencyTableViewController {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return configurations.count
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    configProperty.swap(configurations[indexPath.row])
    tableView.deselectRow(at: indexPath, animated: true)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DisposableCell
    let config = configurations[indexPath.row]
    cell.textLabel?.text = config.agency.name

    cell.disposable += configProperty.map({ $0.id == config.id ? UITableViewCellAccessoryType.checkmark : .none })
      .producer.startWithValues { cell.accessoryType = $0 }
    return cell
  }
}
