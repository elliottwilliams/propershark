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
//    @IBOutlet weak var routeDescription: UILabel!
    @IBOutlet weak var routeTimer: UILabel!
    @IBOutlet weak var routeTitle: UILabel!
//    @IBOutlet weak var routeCaption: UILabel!
    @IBOutlet weak var routeID: UILabel!
    @IBOutlet weak var capacityIndicator: RouteBadge!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        capacityIndicator.outerStrokeWidth = 0
        capacityIndicator.outerStrokeGap = 0
    }

//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
}
