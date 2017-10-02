//
//  OverlayButton.swift
//  Proper
//
//  Created by Elliott Williams on 9/30/17.
//  Copyright © 2017 Elliott Williams. All rights reserved.
//

import Foundation
import UIKit

class OverlayButton: UIButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure() {
    // Font
    let font = UIFont.preferredFont(forTextStyle: .caption2)
    let em = font.pointSize
    titleLabel?.font = font

    // Colors
    backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.1, alpha: 0.8)
    setTitleColor(UIColor.white, for: .normal)

    // Sizing
    contentEdgeInsets = UIEdgeInsets(top: 0.64*em,    left: 0.85*em,
                                     bottom: 0.64*em, right: 0.85*em)

    // Borders
    layer.borderColor = UIColor.white.cgColor
    layer.borderWidth = 1.0
  }

  override func layoutSubviews() {
    layer.cornerRadius = frame.height/2
    super.layoutSubviews()
  }
}
