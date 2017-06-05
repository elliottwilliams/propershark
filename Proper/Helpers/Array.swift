//
//  Array.swift
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

extension Array where Element: Hashable {
  func indexMap() -> [Element: Index] {
    return self.enumerated().reduce([:], { acc, pair in
      var dict = acc
      let (i, v) = pair
      dict[v] = i
      return dict
    })
  }
}
