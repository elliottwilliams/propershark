//
//  Mutable.swift
//  Proper
//
//  Created by Elliott Williams on 7/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Curry

struct Mutable<M: Base> {
    private var attributes: [String: MutableProperty<Any>] = [:]
    private var types: [String: Any.Type] = [:]
    static var blacklistedProperties: [String] { return ["namespace, identifier"] }
    
    init(model: M) {
        let mirror = Mirror(reflecting: model)
        for child in mirror.children {
            if let property = child.label where !Mutable.blacklistedProperties.contains(property) {
                self.attributes[property] = MutableProperty<Any>(child.value)
                self.types[property] = child.value.dynamicType
            }
        }
    }
    
    subscript(key: String) -> MutableProperty<Any>? {
        return attributes[key]
    }
}