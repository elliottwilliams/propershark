//
//  StationUpcomingHeaderFooterView.swift
//  Proper
//
//  Created by Elliott Williams on 12/29/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class StationUpcomingHeaderFooterView: UITableViewHeaderFooterView {
    var cell: StationUpcomingTableViewCell?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let cell = NSBundle.mainBundle().loadNibNamed("StationUpcomingTableViewCell", owner: self, options: nil)![0]
            as! StationUpcomingTableViewCell
        addSubview(cell)
        self.cell = cell
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        cell?.prepareForReuse()
    }

    func apply(station: MutableStation) {
        cell?.apply(station)
    }
}
