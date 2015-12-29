//
//  TransitNavigationItem.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 11/15/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class TransitNavigationItem: UINavigationItem {

    var uppercase:Bool = true
    
    override var title: String? {
        get { return super.title }
        set(newTitle) {
            return super.title = (uppercase) ? newTitle?.uppercaseString : newTitle
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        super.title = (uppercase) ? title?.uppercaseString : title
    }
}
