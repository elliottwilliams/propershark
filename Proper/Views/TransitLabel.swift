//
//  TransitLabel.swift
//  Proper
//
//  Created by Elliott Williams on 11/15/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class TransitLabel: UILabel {

  var uppercase = false {
    didSet { updateText(to: _text) }
  }

  private var _text: String?
  override var text: String? {
    get { return super.text }
    set(newText) { updateText(to: newText) }
  }

  func updateText(to newText: String?) {
    _text = newText
    super.text = (self.uppercase) ? newText?.uppercased() : newText
  }

}
