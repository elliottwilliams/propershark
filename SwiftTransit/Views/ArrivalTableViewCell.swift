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
    @IBOutlet weak var ornament: UIView!
    
    var badge: RouteBadge!

    override func awakeFromNib() {
        // Clear ornament background, which is set in IB to make the ornament visible
        self.ornament.backgroundColor = UIColor.clearColor()
        
        // Create badge programmatically
        let badge = RouteBadge(frame: CGRectMake(8, 8, 28, 28))
        badge.outerStrokeWidth = 0
        badge.outerStrokeGap = 0
        
        self.ornament.addSubview(badge)
        self.badge = badge
    }

//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
}
