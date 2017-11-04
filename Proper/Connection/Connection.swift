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
import SystemConfiguration

typealias ConnectionSP = SignalProducer<Connection, ProperError>

class Connection: NSObject, CachedConnectionProtocol {
  fileprivate let wamp: MDWamp
  fileprivate let (signal, observer) = Signal<Connection, ProperError>.pipe()
  let lastEventCache = LastEventCache()
  fileprivate static var connections: [AnyHashable: Connection] = [:]

  var isConnected: Bool { return wamp.isConnected() }
  fileprivate var isConnecting: Bool = false
  fileprivate var connectionTimeoutAction: ScopedDisposable<AnyDisposable>? = nil
  fileprivate var errors: NotificationObserver = ToastNotificationViewController.sharedObserver
  fileprivate var uri: URL

  fileprivate init(connectionConfig config: ConnectionConfig) {
    let transport = MDWampTransportWebSocket(server: config.server,
                                             protocolVersions: [kMDWampProtocolWamp2msgpack, kMDWampProtocolWamp2json])
    NSLog("[Connection.init] Created transport for \(config.server)")
    wamp = MDWamp(transport: transport, realm: config.realm, delegate: nil)
    uri = config.server
    super.init()
    wamp.delegate = self
  }

  func connect() {
    guard !isConnecting, let reachable = Connection.isReachable(uri: uri) else {
      return
    }

    guard reachable else {
      observer.send(error: .unreachable)
      return
    }

    isConnecting = true
    wamp.connect()
    NSLog("[Connection.connect]")

    if let timeout = QueueScheduler.main.schedule(after: Date(timeIntervalSinceNow: 10), action: { [weak self] in
      self?.observer.send(error: .timeout(rpc: "unable to connect"))
    }) {
      connectionTimeoutAction = ScopedDisposable(timeout)
    }
  }

  func disconnect() {
    NSLog("[Connection.disconnect]")
    connectionTimeoutAction?.dispose()
    wamp.disconnect()
  }

  private static func isReachable(uri: URL) -> Bool? {
    guard let hostname = uri.host,
      let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
        return nil
    }

    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(ref, &flags) else {
      return nil
    }

    return flags.contains(.reachable)
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
    let cachingSubscription = updatingCache(withEventsFrom: subscription, for: topic)
    return cachingSubscription
  }

  /// Call `proc` and forward the result. Disposing the signal created will cancel the RPC call.
  func call(_ proc: String, with args: WampArgs = [], kwargs: WampKwargs = [:]) -> EventProducer {
    let cache = cacheLookup(proc, args, kwargs)
    let rawServer = wamp.callWithSignal(proc, args, kwargs, [:])
      .timeout(after: 10.0, raising: .timeout(rpc: proc), on: QueueScheduler.main)
      .on(failed: { [weak self] _ in self?.errors.send(value: "Request timed out. Retrying…") },
          value:  { [weak self] _ in self?.errors.send(value: nil) })
      .restarting(every: 0.5, on: .main)
    let server = rawServer
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
    let producer = SignalProducer<Connection, ProperError> { observer, disposable in
      let saved = connections[config.hashed]
      switch saved {
      case .some(let saved) where saved.isConnected:
        observer.send(value: saved)
      case .some(let saved): // otherwise
        disposable += saved.signal.observe(observer)
        saved.connect()
      case .none:
        let connection = Connection(connectionConfig: config)
        disposable += connection.signal.observe(observer)
        connection.connect()
        connections[config.hashed] = connection
      }
    }
    let notifications = ToastNotificationViewController.sharedObserver
    return producer
      .on(failed: { _ in
        connections[config.hashed]?.wamp.delegate = nil // because MDWamp is dumb and uses `unowned_unretained` not `weak`
        connections[config.hashed] = nil
        notifications.send(value: "Connection interrupted. Reconnecting…")
      }, value: { _ in notifications.send(value: nil) })
      .restarting(every: 0.5, on: .main)
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
