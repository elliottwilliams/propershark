//
//  BadgeViewLabel.swift
//  Proper
//
//  Created by Elliott Williams on 12/30/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class BadgeViewLabel: UILabel {
    override func awakeFromNib() {
        // Configure the label's font size
        self.font = self.font.fontWithSize(self.bounds.height * 0.55)
        
        // Position the layer above the badge layers
        self.layer.zPosition = 15.0
    }
}
