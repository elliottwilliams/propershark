//  RouteBadge.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/18/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import Colours

class RouteBadge: UIView {
    
    // MARK: Properties
    
    var capacity = 0.0 {
        didSet { updateCapacity() }
    }
    var outerStrokeWidth = 5.0 {
        didSet { updateStroke() }
    }
    var outerStrokeGap = 5.0 {
        didSet { updateStroke() }
    }
    var routeNumber: String? {
        didSet { updateRouteNumber() }
    }
    var color: UIColor = UIColor.redColor() {
        didSet { updateColor() }
    }
    
    let _colorSpace = CGColorSpaceCreateDeviceRGB()
    let _outerBadge = CAShapeLayer()
    let _innerBadge = CAShapeLayer()
    let _filledInnerBadge = CAShapeLayer()
    let _capacityCoverMask = CAShapeLayer()
    var _label: UILabel?
    var _lightColor = UIColor(red: 1, green: 188/255, blue: 188/255, alpha: 1)
    var _strokeColor = UIColor.lightTextColor()

    // MARK: Private properties
    
    private var width: CGFloat!
    private var outerRadius: CGFloat!
    private var innerWidth: CGFloat!
    private var innerRadius: CGFloat!
    private var centerX: CGFloat!
    private var centerY: CGFloat!
    private var capacityCover: CGFloat!
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Calculate drawing measurements and draw the badge layers
        setColors()
        calculateDrawingMeasurements()
        drawBadge()
        insertLayers()
        insertLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setColors()
        calculateDrawingMeasurements()
        drawBadge()
        insertLayers()
        insertLabel()
    }
    
    // MARK: Property-setting calculations
    
    func setColors() {
        self.backgroundColor = UIColor.clearColor()
        _lightColor = self.color.lightenedColor(0.8)
        _strokeColor = UIColor.snowColor()
        
        _label?.textColor = _strokeColor
    }
    
    func calculateDrawingMeasurements() {
        self.width = self.bounds.width
        
        self.innerWidth = CGFloat(width - 2 * CGFloat(outerStrokeWidth + outerStrokeGap))
        self.innerRadius = (innerWidth / 2) - CGFloat(outerStrokeWidth/2)
        self.centerX = width / 2
        self.centerY = centerX
        
        self.outerRadius = (width / 2) - CGFloat(outerStrokeWidth)
        self.capacityCover = innerWidth * CGFloat(1 - capacity)
    }
    
    // MARK: Idempotent calculations
    
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
    
    func labelMeasurements() -> (margin: CGFloat, size: CGFloat, fontSize: CGFloat) {
        return (margin: width * 0.1, size: width * 0.8, fontSize: innerWidth * 0.55)
    }
    
    // MARK: Setup draw code
    
    func insertLayers() {
        self.layer.addSublayer(_outerBadge)
        self.layer.addSublayer(_filledInnerBadge)
        self.layer.addSublayer(_innerBadge)
    }
    
    func insertLabel() {
        let (margin, size, fontSize) = labelMeasurements()
        let label = UILabel(frame: CGRectMake(margin, margin, size, size))
        label.font = UIFont.systemFontOfSize(fontSize, weight: UIFontWeightSemibold)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        label.text = self.routeNumber
        self.addSubview(label)
        _label = label
    }
    
    // MARK: Reusable draw code
    
    func drawBadge() {
        calculateDrawingMeasurements()
        
        _outerBadge.path = outerPath()
        _outerBadge.strokeColor = self.color.CGColor
        _outerBadge.fillColor = _strokeColor.CGColor
        _outerBadge.lineWidth = CGFloat(outerStrokeWidth)
        
        _capacityCoverMask.path = capacityCoverPath(self.capacityCover)
        _capacityCoverMask.fillColor = UIColor.blackColor().CGColor
        
        _innerBadge.path = innerPath()
        _innerBadge.fillColor = self.color.CGColor
        _innerBadge.mask = _capacityCoverMask
        
        _filledInnerBadge.path = innerPath()
        _filledInnerBadge.fillColor = _lightColor.CGColor
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
        // Label font size is dependent on inner width
        let fontSize = labelMeasurements().fontSize
        _label?.font = _label?.font.fontWithSize(fontSize)
    }
    
    func updateRouteNumber() {
        self._label?.text = self.routeNumber
    }
    
    func updateColor() {
        setColors()
        _outerBadge.strokeColor = self.color.CGColor
        _outerBadge.fillColor = _strokeColor.CGColor
        _innerBadge.fillColor = self.color.CGColor
        _filledInnerBadge.fillColor = self.color.CGColor
    }
    
   
}