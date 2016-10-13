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
    func displayError(error: ProperError) {
        let alert = UIAlertController(title: "An improper error:",
                                      message: String(error),
                                      preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
        NSLog("[ProperViewController.displayError] \(error)")
    }

    func resetParentNavigationBar() {
        guard let bar = self.navigationController?.navigationBar else {
            return
        }
        Self.resetNavigationBar(bar)
    }
}

extension ProperViewController {
    static func resetNavigationBar(bar: UINavigationBar) {
        let reference = UINavigationBar()
        bar.tintColor = reference.tintColor
        bar.barTintColor = reference.barTintColor
        bar.shadowImage = reference.shadowImage
        bar.barStyle = reference.barStyle
    }
}
