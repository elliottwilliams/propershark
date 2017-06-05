//
//  Badge.swift
//  Proper
//
//  Created by Elliott Williams on 3/19/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import GameKit
import ReactiveSwift

/**
 Data representing a station's badge. The badge consists of a name and a color. `Badge` instances are used to create
 `BadgeView` instances, which render badges in the UI.
 */
struct Badge {
  //    var name: String
  //    let color: UIColor
  let name: MutableProperty<String>
  let color: MutableProperty<UIColor>

  private static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters
  private static let alphabetLength = 26
  static func letter(for idx: Int) -> String {
    let i = alphabet.index(alphabet.startIndex, offsetBy: idx % alphabetLength)
    return String(alphabet[i])
  }

  init(alphabetIndex idx: Int, color: UIColor) {
    self.init(name: Badge.letter(for: idx), color: color)
  }

  init(name: String, color: UIColor) {
    self.name = .init(name)
    self.color = .init(color)
  }

  init<H: Hashable>(name: String, seedForColor seed: H) {
    self.init(name: name, color: Badge.color(basedOn: seed))
  }

  init<H: Hashable>(alphabetIndex idx: Int, seedForColor seed: H) {
    self.init(name: Badge.letter(for: idx), color: Badge.color(basedOn: seed))
  }

  func set(numericalIndex idx: Int) {
    name.swap(Badge.letter(for: idx))
  }

  /**
   Generate a pseudorandom color given a hashable seed. Using this generator, badges can have a color generated from
   the station's identifier.
   */
  static func color<H: Hashable>(basedOn seed: H) -> UIColor {
    let src = GKMersenneTwisterRandomSource(seed: UInt64(abs(seed.hashValue)))
    let gen = GKRandomDistribution(randomSource: src, lowestValue: 0, highestValue: 255)
    let h = CGFloat(gen.nextInt()) / 256.0
    // Saturation and luminance stay between 0.5 and 1.0 to avoid white and excessively dark colors.
    let s = CGFloat(gen.nextInt()) / 512.0 + 0.5
    let l = CGFloat(gen.nextInt()) / 512.0 + 0.5
    return UIColor(hue: h, saturation: s, brightness: l, alpha: CGFloat(1))
  }
}
