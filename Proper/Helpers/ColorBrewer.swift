//
//  ColorBrewer.swift
//  Proper
//
//  Created by Elliott Williams on 10/2/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class ColorBrewer {

  let scheme: [(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)]
  private let rSpline: (CGFloat) -> (CGFloat)
  private let gSpline: (CGFloat) -> (CGFloat)
  private let bSpline: (CGFloat) -> (CGFloat)
  private let aSpline: (CGFloat) -> (CGFloat)

  init(scheme: [(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)]) {
    self.scheme = scheme
    rSpline = Interpolation.makeUniform(controlPoints: scheme.map({ $0.red }), degree: 2)
    gSpline = Interpolation.makeUniform(controlPoints: scheme.map({ $0.green }), degree: 2)
    bSpline = Interpolation.makeUniform(controlPoints: scheme.map({ $0.blue }), degree: 2)
    aSpline = Interpolation.makeUniform(controlPoints: scheme.map({ $0.alpha }), degree: 2)
  }

  convenience init(uiColors scheme: [UIColor]) {
    self.init(scheme: scheme.map({ ($0.red(), $0.green(), $0.blue(), $0.alpha()) }))
  }

  func interpolatedColor(at pos: CGFloat) -> UIColor {
    return UIColor(red: CGFloat(rSpline(pos)),
                   green: CGFloat(gSpline(pos)),
                   blue: CGFloat(bSpline(pos)),
                   alpha: CGFloat(aSpline(pos)))
  }

  static let purpleRed = ColorBrewer(uiColors: [
    UIColor(hex: "df65b0"), UIColor(hex: "e7298a"), UIColor(hex: "ce1256"),
    UIColor(hex: "980043"), UIColor(hex: "67001f"),
  ])
}
