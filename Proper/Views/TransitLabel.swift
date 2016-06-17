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
        didSet { updateTextTo(_text) }
    }
    
    private var _text: String?
    override var text: String? {
        get { return super.text }
        set(newText) { updateTextTo(newText) }
    }
    
    func updateTextTo(newText: String?) {
        _text = newText
        super.text = (self.uppercase) ? newText?.uppercaseString : newText
    }

}
