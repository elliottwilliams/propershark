//
//  Signal+xctAssertValues.swift
//  Proper
//
//  Created by Elliott Williams on 6/4/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import XCTest

extension Signal {
    /// Test only: Calls XCTFail if an error appears in the signal.
    func xctAssertValues() -> Signal<Value, NoError> {
        return flatMapError({ error in
            XCTFail("\(error.localizedDescription)")
            return SignalProducer.empty
        })
    }
}

extension SignalProducer {
    /// Test only: Calls XCTFail if an error appears in the produced signal.
    func xctAssertValues() -> SignalProducer<Value, NoError> {
        return lift({ $0.xctAssertValues() })
    }
}
