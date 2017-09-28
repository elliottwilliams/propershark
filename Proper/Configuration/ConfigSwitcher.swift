//
//  ConfigSwitcher.swift
//  Proper
//
//  Created by Elliott Williams on 8/15/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

typealias ConfigProperty = MutableProperty<ConfigProtocol>

struct Config {
  typealias DefaultConfig = CitybusConfig

  static let knownConfigurations: [ConfigProtocol.Type] = [
    CitybusConfig.self,
    BartConfig.self
  ]

  static let shared: ConfigProperty = {
    let property = MutableProperty(stored() ?? DefaultConfig())
    property.signal.observeValues(store)
    return property
  }()

  static var producer: SignalProducer<ConfigProtocol, NoError> {
    return shared.producer
  }

  @available(*, deprecated, message: "Avoid depending on global state")
  static var current: ConfigProtocol {
    return shared.value
  }
}

private extension Config {
  static func stored() -> ConfigProtocol? {
    guard let id = UserDefaults.standard.string(forKey: "selectedConfig") else {
      return nil
    }
    return knownConfigurations.first(where: { $0.id == id })?.make()
  }

  static func store(config: ConfigProtocol) {
    UserDefaults.standard.set(type(of: config).id, forKey: "selectedConfig")
  }
}
