//
//  Interpolation.swift
//  Proper
//
//  Created by Elliott Williams on 10/3/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation

public class Interpolation {
  public static func makeBSpline<Number: FloatingPoint>(knots t: [Number],
                                                        controlPoints c: [Number],
                                                        degree p: Int,
                                                        shouldPad: Bool = true) -> (Number) -> Number
  {
    let t = shouldPad ? pad(t, degree: p) : t
    let c = shouldPad ? pad(c, degree: p) : c

    return { x in
      var k = t.count-p-1
      for i in t.indices.reversed().dropFirst() {
        if t[i] <= x && x < t[i+1] {
          k = i
          break
        }
      }

      var d = (0...(p+1)).map({ j -> Number in c[max(j + k - p,0)] })
      for r in 1...p {
        for j in stride(from: p, through: r, by: -1) {
          let alpha = (x - t[j+k-p]) / (t[j+1+k-r] - t[j+k-p])
          d[j] = (1 - alpha) * d[j-1] + alpha * d[j]
        }
      }
      return d[p]
    }
  }

  public static func makeUniform<Number: FloatingPoint>(controlPoints c: [Number], degree p: Int) -> (Number) -> Number {
    return makeBSpline(knots: uniformKnot(c.count), controlPoints: c, degree: p)
  }

  public static func pad<Number: FloatingPoint>(_ t: [Number], degree p: Int) -> [Number] {
    assert(t.count > 0, "`t` must be nonempty")
    let first = Array(repeating: t.first!, count: p)
    let last = Array(repeating: t.last!, count: p)
    return first + t + last
  }

  public static func uniformKnot<Number: FloatingPoint>(_ n: Int) -> [Number] {
    return (0..<n).map({ Number($0)/Number(n-1) })
  }
}
