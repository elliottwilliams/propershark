//
//  Array+SafeIndex.swift
//  Proper
//
//  Created by Elliott Williams on 1/9/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
