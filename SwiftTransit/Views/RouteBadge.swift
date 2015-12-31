//
//  RouteBadge.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/18/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteBadge: UIView {
    
    var capacity = 0.0 {
        didSet { updateCapacity() }
    }
    var outerStrokeWidth = 5.0 {
        didSet { updateStroke() }
    }
    var outerStrokeGap = 5.0 {
        didSet { updateStroke() }
    }
 
    private var width: CGFloat!
    private var outerRadius: CGFloat!
    private var innerWidth: CGFloat!
    private var innerRadius: CGFloat!
    private var centerX: CGFloat!
    private var centerY: CGFloat!
    private var capacityCover: CGFloat!
    private var darkRed: CGColor!
    private var lightRed: CGColor!
    
    let _colorSpace = CGColorSpaceCreateDeviceRGB()
    let _outerBadge = CAShapeLayer()
    let _innerBadge = CAShapeLayer()
    let _filledInnerBadge = CAShapeLayer()
    let _capacityCoverMask = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Calculate drawing measurements and draw the badge layers
        determineColors()
        calculateDrawingMeasurements()
        drawBadge()
        insertLayers()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        determineColors()
        calculateDrawingMeasurements()
        drawBadge()
        insertLayers()
    }

    /*override func awakeFromNib() {
        // red is set in IB so that it's visible, clear it now
        self.backgroundColor = UIColor.clearColor()
        
        // Set colors
        self.darkRed = CGColorCreate(_colorSpace, [1.0, 0.0, 0.0, 1.0])!
        self.lightRed = CGColorCreate(_colorSpace, [1.0, 188/255, 188/255, 1.0])!
        
        // Calculate drawing measurements and draw the badge layers
        calculateDrawingMeasurements()
        drawBadge()
    }*/
    
    func determineColors() {
        self.backgroundColor = UIColor.clearColor()
        self.darkRed = CGColorCreate(_colorSpace, [1.0, 0.0, 0.0, 1.0])!
        self.lightRed = CGColorCreate(_colorSpace, [1.0, 188/255, 188/255, 1.0])!
    }
    
    func insertLayers() {
        self.layer.addSublayer(_outerBadge)
        self.layer.addSublayer(_filledInnerBadge)
        self.layer.addSublayer(_innerBadge)
    }
    
    func calculateDrawingMeasurements() {
        self.width = self.bounds.width
        
        self.innerWidth = CGFloat(width - 2 * CGFloat(outerStrokeWidth + outerStrokeGap))
        self.innerRadius = (innerWidth / 2) - CGFloat(outerStrokeWidth/2)
        self.centerX = width / 2
        self.centerY = centerX
        
        self.outerRadius = (width / 2) - CGFloat(outerStrokeWidth)
        self.capacityCover = (innerRadius * 2) * CGFloat(1 - capacity)
    }
    
    func outerPath() -> CGMutablePath {
        let outer = CGPathCreateMutable()
        CGPathAddArc(outer, nil, centerX, centerY, outerRadius, 0, CGFloat(2*M_PI), true)
        return outer
    }
    
    func innerPath() -> CGMutablePath {
        let inner = CGPathCreateMutable()
        CGPathAddArc(inner, nil, centerX, centerY, innerRadius, 0, CGFloat(2*M_PI), true)
        return inner
    }
    
    func capacityCoverPath(height: CGFloat) -> CGPath {
        return CGPathCreateWithRect(CGRectMake(0, CGFloat(outerStrokeWidth + outerStrokeGap), width, height), nil)
    }
    
    func drawBadge() {
        calculateDrawingMeasurements()
        
        _outerBadge.path = outerPath()
        _outerBadge.strokeColor = darkRed
        _outerBadge.fillColor = UIColor.whiteColor().CGColor
        _outerBadge.lineWidth = CGFloat(outerStrokeWidth)
        
        _capacityCoverMask.path = capacityCoverPath(self.capacityCover)
        _capacityCoverMask.fillColor = UIColor.blackColor().CGColor
        
        _innerBadge.path = innerPath()
        _innerBadge.fillColor = darkRed
        _innerBadge.mask = _capacityCoverMask
        _innerBadge.zPosition = 10.0
        
        _filledInnerBadge.path = innerPath()
        _filledInnerBadge.fillColor = lightRed
        _filledInnerBadge.zPosition = 8.0
    }
    
    func updateCapacity() {
        calculateDrawingMeasurements()
        let anim = CABasicAnimation(keyPath: "path")
        let path = self.capacityCoverPath(self.capacityCover)
        anim.fromValue = _capacityCoverMask.path
        anim.toValue = path
        anim.duration = 0.25
        _capacityCoverMask.addAnimation(anim, forKey: "path")
        _capacityCoverMask.path = path
    }
    
    func updateStroke() {
        drawBadge()
    }
    
   
}