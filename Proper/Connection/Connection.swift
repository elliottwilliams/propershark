//
//  Connection.swift
//  Proper
//
//  Created by Elliott Williams on 6/19/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import MDWamp
import ReactiveSwift
import Result

class Connection: NSObject {
  typealias ConnectionProducer = SignalProducer<MDWamp, ProperError>

  static var sharedInstance = Connection.init()

  // MARK: Private
  fileprivate var config = Config.shared
  fileprivate lazy var connection = MutableProperty<MDWamp?>(nil)
  fileprivate let disposable = ScopedDisposable(CompositeDisposable())

  override init() {
    super.init()

    // Connect the wamp instance based on the latest configuration, and disconnect from old instances.
    disposable.inner += config.producer
      .map(makeConnection)
      .map(Optional.init)
      .combinePrevious(nil)
      .startWithValues { prev, next in
        prev?.disconnect()
        next?.connect()
    }
  }
}

// MARK: - Connection forming
extension Connection {

  // MARK: Private

  /// Returns an `MDWamp` object created using `config`. Disconnects the previous connection, if it exists, and connects
  /// the returned connection.
  fileprivate func makeConnection(config: ConfigProtocol) -> MDWamp {
    let ws = MDWampTransportWebSocket(server: config.connection.server,
                                      protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
    return MDWamp(transport: ws, realm: config.connection.realm, delegate: self)!
  }
}

// MARK: - Communication methods
extension Connection: ConnectionType {
  /// Subscribe to `topic` and forward parsed events. Disposing of signals created from this method will unsubscribe
  /// `topic`.
  func subscribe(to topic: String) -> EventProducer {
    return connection.producer.skipNil()
      .map { wamp in wamp.subscribeWithSignal(topic) }
      .flatten(.latest)
      .map { TopicEvent.parse(from: topic, event: $0) }
      .unwrapOrSendFailure(ProperError.eventParseFailure)
      .logEvents(identifier: "Connection.subscribe", logger: logSignalEvent)
  }

  /// Call `proc` and forward the result. Disposing the signal created will cancel the RPC call.
  func call(_ proc: String, with args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
    return connection.producer.skipNil()
      .map({ $0.callWithSignal(proc, args, kwargs, [:])
        .timeout(after: 10.0, raising: .timeout(rpc: proc), on: QueueScheduler.main) })
      .flatten(.latest)
      .map { TopicEvent.parse(fromRPC: proc, args, kwargs, $0) }
      .unwrapOrSendFailure(ProperError.eventParseFailure)
  }
}

// MARK: - MDWampClientDelegate
extension Connection: MDWampClientDelegate {
  func mdwamp(_ wamp: MDWamp!, sessionEstablished info: [AnyHashable: Any]!) {
    NSLog("[Connection] Session established")
    connection.swap(wamp)
  }

  func mdwamp(_ wamp: MDWamp!, closedSession code: Int, reason: String!, details: WampKwargs!) {
    NSLog("[Connection] Session closed, code=\(code) reason=\(reason)")

    if code == MDWampConnectionCloseCode.closed.rawValue {
      // We're switching connections.
    } else {
      // TODO show connection error
      fatalError(reason)
    }
  }
}

// MARK: - MDWamp extension
extension MDWamp {
  /// Follows semantics of `call` but returns a signal producer, rather than taking a result callback.
  func callWithSignal(_ procUri: String, _ args: WampArgs, _ argsKw: WampKwargs, _ options: [AnyHashable: Any])
    -> SignalProducer<MDWampResult, ProperError>
  {
    return SignalProducer<MDWampResult, ProperError> { observer, _ in
      NSLog("[Connection] Calling \(procUri)")
      self.call(procUri, args: args, kwArgs: argsKw, options: options) { result, error in
        if error != nil {
          observer.send(error: .mdwampError(topic: procUri, object: error))
          return
        }
        observer.send(value: result!)
        observer.sendCompleted()
      }
      }.logEvents(identifier: "MDWamp.callWithSignal", logger: logSignalEvent)
  }

  func subscribeWithSignal(_ topic: String) -> SignalProducer<MDWampEvent, ProperError> {
    return SignalProducer<MDWampEvent, ProperError> { observer, disposable in
      self.subscribe(
        topic,
        options: nil,
        onEvent: { event in event.map(observer.send(value:)) },
        result: { error in
          NSLog("[Connection] Subscribed to \(topic)")
          if error != nil { observer.send(error: .mdwampError(topic: topic, object: error)) }
      }
      )
      disposable.add {
        self.unsubscribe(topic) { error in
          NSLog("[Connection] Unsubscribed from \(topic)")
          if error != nil { observer.send(error: .mdwampError(topic: topic, object: error)) }
        }
      }
      }.logEvents(identifier: "MDWamp.subscribeWithSignal", logger: logSignalEvent)
  }
}
