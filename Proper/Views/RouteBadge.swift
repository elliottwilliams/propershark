//  RouteBadge.swift
//  Proper
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
    var outerStrokeWidth = 0.0 {
        didSet { updateStroke() }
    }
    var outerStrokeGap = 0.0 {
        didSet { updateStroke() }
    }
    var routeNumber: String? {
        didSet { updateRouteNumber() }
    }
    var color: UIColor = UIColor.lightGrayColor() {
        didSet { updateColor() }
    }
    var highlighted: Bool = false {
        didSet { highlightChanged(from: oldValue, to: highlighted) }
    }

    // MARK: Private properties
    
    private let outerBadge = CAShapeLayer()
    private let innerBadge = CAShapeLayer()
    private let filledInnerBadge = CAShapeLayer()
    private let capacityCoverMask = CAShapeLayer()
    private var label: UILabel?
    private var lightColor = UIColor(red: 1, green: 188/255, blue: 188/255, alpha: 1)
    private var strokeColor = UIColor.lightTextColor()

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
        backgroundColor = UIColor.clearColor()
        lightColor = color.lightenedColor(0.8)
        strokeColor = UIColor.snowColor()
        
        label?.textColor = strokeColor
    }
    
    func calculateDrawingMeasurements() {
        width = bounds.width
        
        innerWidth = CGFloat(width - 2 * CGFloat(outerStrokeWidth + outerStrokeGap))
        innerRadius = (innerWidth / 2) - CGFloat(outerStrokeWidth/2)
        centerX = width / 2
        centerY = centerX
        
        outerRadius = (width / 2) - CGFloat(outerStrokeWidth)
        capacityCover = innerWidth * CGFloat(1 - capacity)
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
        layer.addSublayer(outerBadge)
        layer.addSublayer(filledInnerBadge)
        layer.addSublayer(innerBadge)
    }
    
    func insertLabel() {
        let (margin, size, fontSize) = labelMeasurements()
        let label = UILabel(frame: CGRectMake(margin, margin, size, size))
        label.font = UIFont.systemFontOfSize(fontSize, weight: UIFontWeightSemibold)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        label.text = routeNumber
        addSubview(label)
        self.label = label
    }
    
    // MARK: Reusable draw code
    
    func drawBadge() {
        calculateDrawingMeasurements()
        
        outerBadge.path = outerPath()
        outerBadge.strokeColor = color.CGColor
        outerBadge.fillColor = strokeColor.CGColor
        outerBadge.lineWidth = CGFloat(outerStrokeWidth)
        
        capacityCoverMask.path = capacityCoverPath(capacityCover)
        capacityCoverMask.fillColor = UIColor.blackColor().CGColor
        
        innerBadge.path = innerPath()
        innerBadge.fillColor = color.CGColor
        innerBadge.mask = capacityCoverMask
        
        filledInnerBadge.path = innerPath()
        filledInnerBadge.fillColor = lightColor.CGColor
    }
    
    func updateCapacity() {
        calculateDrawingMeasurements()
        let anim = CABasicAnimation(keyPath: "path")
        let path = capacityCoverPath(capacityCover)
        anim.fromValue = capacityCoverMask.path
        anim.toValue = path
        anim.duration = 0.25
        capacityCoverMask.addAnimation(anim, forKey: "path")
        capacityCoverMask.path = path
    }
    
    func updateStroke() {
        drawBadge()
        // Label font size is dependent on inner width
        let fontSize = labelMeasurements().fontSize
        label?.font = label?.font.fontWithSize(fontSize)
    }
    
    func updateRouteNumber() {
        label?.text = routeNumber
    }
    
    func updateColor() {
        setColors()
        outerBadge.strokeColor = color.CGColor
        outerBadge.fillColor = strokeColor.CGColor
        innerBadge.fillColor = color.CGColor
        filledInnerBadge.fillColor = color.CGColor
    }

    func highlightChanged(from wasHighlighted: Bool, to highlighted: Bool) {
        guard wasHighlighted != highlighted else { return }
        UIView.animateWithDuration(0) {
            self.color = highlighted ? self.color.darkenedColor(2/5) : self.color.lightenedColor(2/3)
        }
    }
   
}
