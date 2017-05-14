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
    func viewWillDisappear(_ animated: Bool)
}

extension ProperViewController where Self: UIViewController {

    /// Show a model alert corresponding to the error message of a `PSError`.
    func displayError(_ error: ProperError) {
        let alert = UIAlertController(title: "An improper error:",
                                      message: String(error),
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
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
    static func resetNavigationBar(_ bar: UINavigationBar) {
        let reference = UINavigationBar()
        bar.tintColor = reference.tintColor
        bar.barTintColor = reference.barTintColor
        bar.shadowImage = reference.shadowImage
        bar.barStyle = reference.barStyle
    }
}
