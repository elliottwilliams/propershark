//
//  SignalChain.swift
//  Proper
//
//  Created by Elliott Williams on 3/18/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

protocol SignalChain {
  associatedtype Input
  associatedtype Output

  static func chain(connection: ConnectionType, producer: SignalProducer<Input, ProperError>) ->
    SignalProducer<Output, ProperError>
}

extension SignalChain {
  static func chain(connection: ConnectionType, producer: SignalProducer<Input, NoError>) ->
    SignalProducer<Output, ProperError>
  {
    return chain(connection: connection, producer: producer.promoteErrors(ProperError.self))
  }
}
