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

typealias ConnectionSP = SignalProducer<Connection, ProperError>

class Connection: NSObject, CachedConnectionProtocol {
  fileprivate let wamp: MDWamp
  fileprivate let (signal, observer) = Signal<Connection, ProperError>.pipe()
  let lastEventCache = LastEventCache()
  fileprivate static var connections: [AnyHashable: Connection] = [:]

  var isConnected: Bool { return wamp.isConnected() }
  fileprivate var isConnecting: Bool = false
  fileprivate var connectionTimeoutAction: ScopedDisposable<AnyDisposable>? = nil

  fileprivate init(connectionConfig config: ConnectionConfig) {
    let transport = MDWampTransportWebSocket(server: config.server,
                                             protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
    NSLog("[Connection.init] Created transport for \(config.server)")
    wamp = MDWamp(transport: transport, realm: config.realm, delegate: nil)
    super.init()
    wamp.delegate = self
  }

  func connect() -> Disposable {
    if !isConnecting {
      isConnecting = true
      wamp.connect()
      NSLog("[Connection.connect]")
    }
    if let timeout = QueueScheduler.main.schedule(after: Date(timeIntervalSinceNow: 10), action: { [weak self] in
      self?.observer.send(error: .timeout(rpc: "unable to connect"))
    }) {
      connectionTimeoutAction = ScopedDisposable(timeout)
    }
//    return ActionDisposable { [weak self] in self?.disconnect() }
    return ActionDisposable { }
  }

  func disconnect() {
    NSLog("[Connection.disconnect]")
    connectionTimeoutAction?.dispose()
    wamp.disconnect()
  }
}

extension Connection: ConnectionType {
  /// Subscribe to `topic` and forward parsed events. Disposing of signals created from this method will unsubscribe
  /// `topic`.
  func subscribe(to topic: String) -> EventProducer {
    let subscription = wamp
      .subscribeWithSignal(topic)
      .map { TopicEvent.parse(from: topic, event: $0) }
      .unwrapOrSendFailure(ProperError.eventParseFailure)
      .logEvents(identifier: "Connection.subscribe", logger: logSignalEvent)
    return updatingCache(withEventsFrom: subscription, for: topic)
  }

  /// Call `proc` and forward the result. Disposing the signal created will cancel the RPC call.
  func call(_ proc: String, with args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
    let cache = cacheLookup(proc, args, kwargs)
    let server = wamp.callWithSignal(proc, args, kwargs, [:])
      .timeout(after: 10.0, raising: .timeout(rpc: proc), on: QueueScheduler.main)
      .map { TopicEvent.parse(fromRPC: proc, args, kwargs, $0) }
      .unwrapOrSendFailure(ProperError.eventParseFailure)
      .logEvents(identifier: "Connection.call(proc: \(proc))", events: Set([.starting, .value, .failed]),
                 logger: logSignalEvent)
    return SignalProducer<EventProducer, ProperError>([cache, server])
      .flatten(.concat).take(first: 1)
  }
}

// MARK: - MDWampClientDelegate
extension Connection: MDWampClientDelegate {
  func mdwamp(_ wamp: MDWamp!, sessionEstablished info: [AnyHashable : Any]!) {
    isConnecting = false
    connectionTimeoutAction?.dispose()
    observer.send(value: self)
  }

  func mdwamp(_ wamp: MDWamp!, closedSession code: Int, reason: String!, details: [AnyHashable : Any]!) {
    connectionTimeoutAction?.dispose()
    if MDWampConnectionCloseCode(rawValue: code) == .closed {
      observer.sendCompleted()
    } else {
      observer.send(error: .connectionLost(reason: reason))
    }
  }
}

// MARK: - Factory
extension Connection {
  static func makeFromConfig(connectionConfig config: ConnectionConfig) -> SignalProducer<Connection, ProperError> {
    return SignalProducer { observer, disposable in
      let saved = connections[config.hashed]
      switch saved {
      case .some(let saved) where saved.isConnected:
        observer.send(value: saved)
      case .some(let saved): // otherwise
        disposable += saved.signal.observe(observer)
        disposable += saved.connect()
      case .none:
        let connection = Connection(connectionConfig: config)
        disposable += connection.signal.observe(observer)
        disposable += connection.connect()
        connections[config.hashed] = connection
      }
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
