//
//  RouteBadge.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/18/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteBadge: UIView {
    
    var capacity = 1.0 {
        didSet { self.setNeedsDisplay() }
    }
    var outerStrokeWidth = 5.0 {
        didSet { self.setNeedsDisplay() }
    }
    var outerStrokeGap = 5.0 {
        didSet { self.setNeedsDisplay() }
    }
    
    override func awakeFromNib() {
        // red is set in IB so that it's visible, clear it now
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let width = self.bounds.width
        
        let innerWidth = CGFloat(width - 2 * CGFloat(outerStrokeWidth + outerStrokeGap))
        let innerRadius = innerWidth / 2
        let centerX = width / 2
        let centerY = centerX
        
        let outerRadius = (width / 2) - CGFloat(outerStrokeWidth)
        let capacityCover = width * CGFloat(capacity)
        
        let darkRed = CGColorCreate(colorSpace, [1.0, 0.0, 0.0, 1.0])
        let lightRed = CGColorCreate(colorSpace, [1.0, 188/255, 188/255, 1.0])

        // Inner red circle
        CGContextSetFillColorWithColor(context, lightRed)
        CGContextAddArc(context, centerX, centerY, innerRadius, 0, CGFloat(2*M_PI), 1)
        CGContextFillPath(context)
        
        // Outer red circle
        CGContextSetStrokeColorWithColor(context, darkRed)
        CGContextAddArc(context, centerX, centerY, outerRadius, 0, CGFloat(2*M_PI), 1)
        CGContextSetLineWidth(context, CGFloat(outerStrokeWidth))
        CGContextStrokePath(context)
        
        // Masked capacity rectangle inside inner circle
        CGContextBeginPath(context)
        CGContextAddArc(context, centerX, centerY, innerRadius, 0, CGFloat(2*M_PI), 1)
        CGContextClosePath(context)
        CGContextClip(context)
        
        CGContextSetFillColorWithColor(context, darkRed)
        CGContextAddRect(context, CGRectMake(0, 0, width, capacityCover))
        CGContextFillPath(context)
    }
}
