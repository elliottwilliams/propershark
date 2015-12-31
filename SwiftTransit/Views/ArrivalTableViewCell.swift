//
//  ArrivalTableViewCell
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ArrivalTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var routeTimer: UILabel!
    @IBOutlet weak var routeTitle: UILabel!
    @IBOutlet weak var routeID: UILabel!
//    @IBOutlet weak var badge: RouteBadge!
    @IBOutlet weak var ornament: UIView!
    
    var badge: RouteBadge!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Create badge programmatically
        let badge = RouteBadge(frame: CGRectMake(8, 8, 28, 28))
        badge.outerStrokeWidth = 0
        badge.outerStrokeGap = 0
        
        ornament.addSubview(badge)
        ornament.sendSubviewToBack(badge)
        self.badge = badge
    }

//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
}
