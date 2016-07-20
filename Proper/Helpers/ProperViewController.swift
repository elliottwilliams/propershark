//
//  File.swift
//  Proper
//
//  Created by Elliott Williams on 7/17/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError

protocol ProperViewController {

    // Support properties. Usually private on the conforming view controller.
    var connection: ConnectionType { get set }
    var config: Config { get set }

    /// Produces a signal that completes when the view disappears. No other events shall be fired.
    func onDisappear() -> SignalProducer<(), NoError>
}

extension ProperViewController where Self: UIViewController {

    /// Show a model alert corresponding to the error message of a `PSError`.
    func displayError(error: PSError) {
        self.presentViewController(error.alert as UIViewController, animated: true, completion: nil)
        NSLog("[ProperViewController#displayError] \(error.description), \(error.alert.message)")
    }

    /// Completed when UIViewController.viewDidDisappear(_:) is called.
    func onDisappear() -> SignalProducer<(), NoError> {
        return self.rac_signalForSelector(#selector(UIViewController.viewDidDisappear(_:)))
        .toSignalProducer()
        .map { _ in () }
        .assumeNoError()
    }
}