//
//  ArrivalTableView.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/28/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ArrivalTableView: UITableView {
    override func awakeFromNib() {
        
        // The arrival table uses cells stored in an external nib. Register them now
        self.registerNib(UINib(nibName: "ArrivalTableViewCell", bundle: nil), forCellReuseIdentifier: "ArrivalTableViewCell")
    }
}
