//
//  ScheduleRail.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ScheduleRail: UIView {
    
    // MARK: Properties
    
    var hasVehicle: Bool = false
    var hasStation: Bool = true
    var type: ScheduleRailType = ScheduleRailType.NorthSouth
    
    let _railColor = UIColor.lightGrayColor()
    
    // Use a shape layer as the base layer of this class
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawRail(self.layer as! CAShapeLayer, width: self.frame.width, height: self.frame.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawRail(self.layer as! CAShapeLayer, width: self.frame.width, height: self.frame.height)
    }
    
    func drawRail(layer: CAShapeLayer, width: CGFloat, height: CGFloat) {
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, width/2, 0)
        CGPathAddLineToPoint(path, nil, width/2, height)
        
        layer.path = path
        layer.strokeColor = _railColor.CGColor
        layer.lineWidth = 4.0
    }

}

enum ScheduleRailType {
    case WestSouth
    case NorthWest
    case NorthSouth
}