//
//  Box.swift
//  Proper
//
//  Created by Elliott Williams on 9/3/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import Foundation

class Box<T>: CustomStringConvertible {
  let value: T
  init(_ value: T) {
    self.value = value
  }

  func map<U>(transform f: (T) -> U) -> Box<U> {
    return Box<U>(f(value))
  }

  var description: String { return String(describing: value) }
}
