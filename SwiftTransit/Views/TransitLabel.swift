//
//  TransitLabel.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 11/15/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class TransitLabel: UILabel {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    var uppercase = true
    
    override var text : String? {
        get { return super.text }
        set(newText) {
            return super.text = (self.uppercase) ? newText?.uppercaseString : newText
        }
    }

}
