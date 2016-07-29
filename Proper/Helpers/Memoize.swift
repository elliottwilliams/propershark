//
//  Memoize.swift
//  Proper
//
//  Created by Elliott Williams on 7/29/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import Curry
import Runes

func memoize<T: Hashable, U>(fn: T -> U) -> (T -> U) {
    var memos = [T: U]()
    return { x in
        if let cached = memos[x] {
            return cached
        } else {
            let result = fn(x)

            memos[x] = result
            return result
        }
    }
}


func foo() {
    
}