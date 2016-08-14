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

    // Internal Properties
    var connection: ConnectionType { get set }
    var disposable: CompositeDisposable { get }

    // Should dispose `disposable` and call super.
    func viewWillDisappear(animated: Bool)
}

extension ProperViewController where Self: UIViewController {

    /// Show a model alert corresponding to the error message of a `PSError`.
    func displayError(error: PSError) {
        self.presentViewController(error.alert as UIViewController, animated: true, completion: nil)
        NSLog("[ProperViewController.displayError] \(error.description), \(error.alert.message)")
    }
}