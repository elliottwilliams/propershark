//  BadgeView.swift
//  Proper
//
//  Created by Elliott Williams on 12/18/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import CoreGraphics

class BadgeView: UIView {

    // The nib loaded in setup() provides three views:
    // - container, which fills the bounds of self
    @IBOutlet var container: UIView!
    // - badge, which maintains a 1:1 aspect ratio and which holds the badge shape layers
    @IBOutlet var badge: UIView!
    // - label, which displays text on the badge (e.g. route number)
    @IBOutlet var label: UILabel!
    
    // MARK: Properties

    // Properties that redraw the badge upon modification.
    var capacity: CGFloat = 1.0 {
        didSet { animateCapacityMask(from: oldValue, to: capacity) }
    }
    var color = UIColor.gray {
        didSet { redraw() }
    }
    var strokeColor = UIColor.white {
        didSet {
            label.textColor = strokeColor
            redraw()
        }
    }
    var outerStrokeWidth: CGFloat = 0.0 {
        didSet { redraw() }
    }
    var outerStrokeGap: CGFloat = 0.0 {
        didSet { redraw() }
    }

    // A proxy to the text label contained within the badge.
    var routeNumber: String? {
        get { return label.text }
        set { label.text = newValue }
    }

    // Controls the highlight state of the badge, animating between states.
    var highlighted: Bool = false {
        didSet { changedHighlight(from: oldValue, to: highlighted) }
    }

    // MARK: Private properties
    
    private let outerLayer = CAShapeLayer()
    private let innerLayer = CAShapeLayer()
    private let filledInnerLayer = CAShapeLayer()
    private let capacityCoverMask = CAShapeLayer()

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        // Load, configure, and attach the badge nib.
        Bundle.main.loadNibNamed("BadgeView", owner: self, options: nil)
        container.frame = self.bounds
        addSubview(container)

        // Apply constraints to the view hierarchy before drawing to the layers.
        layoutIfNeeded()

        // Configure the label to stack above the badge shapes and be the stroke color.
        label.layer.zPosition = 15
        label.textColor = strokeColor

        // Insert shape layers.
        [outerLayer, filledInnerLayer, innerLayer].forEach { layer in
            badge.layer.addSublayer(layer)
        }

        // Clear the background placeholder colors.
        backgroundColor = .clear
        badge.backgroundColor = .clear

        // Draw the badge in the next update cycle.
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.layer.frame = self.bounds
        badge.layer.frame = container.bounds
        [outerLayer, filledInnerLayer, innerLayer].forEach { layer in
            layer.frame = badge.layer.bounds
        }
        redraw()
    }
    
    // MARK: Shape calculations
    
    func outerPath(radius: CGFloat) -> CGMutablePath {
        let outer = CGMutablePath()
        let point = CGPoint(x: outerLayer.bounds.midX, y: outerLayer.bounds.midY)
        outer.addArc(center: point, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        return outer
    }
    
    func innerPath(radius: CGFloat) -> CGMutablePath {
        let inner = CGMutablePath()
        let point = CGPoint(x: innerLayer.bounds.midX, y: innerLayer.bounds.midY)
        inner.addArc(center: point, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        return inner
    }
    
    func capacityRect(amount: CGFloat) -> CGPath {
        let height = (1 - amount) * innerLayer.bounds.height
        let rect = CGRect(x: 0, y: outerStrokeWidth + outerStrokeGap, width: innerLayer.bounds.width, height: height)
        return CGPath(rect: rect, transform: nil)
    }
    
    // MARK: Draw code

    func redraw() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let edge = min(badge.bounds.width, badge.bounds.height)
        let innerWidth = edge - 2 * (outerStrokeWidth + outerStrokeGap)
        let innerRadius = innerWidth / 2 - outerStrokeWidth / 2
        let outerRadius = edge / 2 - outerStrokeWidth

        outerLayer.path = outerPath(radius: outerRadius)
        outerLayer.strokeColor = strokeColor.cgColor
        outerLayer.fillColor = color.cgColor
        outerLayer.lineWidth = outerStrokeWidth
        
        capacityCoverMask.path = capacityRect(amount: capacity)
        capacityCoverMask.fillColor = UIColor.black.cgColor
        
        innerLayer.path = innerPath(radius: innerRadius)
        innerLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        innerLayer.mask = capacityCoverMask
        
        filledInnerLayer.path = innerPath(radius: innerRadius)
        filledInnerLayer.fillColor = color.cgColor
        CATransaction.commit()
    }

    // MARK: Animations
    
    func animateCapacityMask(from oldValue: CGFloat, to value: CGFloat) {
        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = capacityRect(amount: oldValue)
        anim.toValue = capacityRect(amount: value)
        anim.duration = 0.25
        capacityCoverMask.add(anim, forKey: "path")

        redraw()
    }

    func changedHighlight(from wasHighlighted: Bool, to shouldHighlight: Bool) {
        // Ensure the highlight state changed.
        guard wasHighlighted != shouldHighlight else { return }

        // Determine color keyframes for the animation by darkening the badge color, or re-lightening it.
        let color = self.color
        let darkened = self.color.darkenedColor(2/5)

        // Avoid the implicit animation by making the color changes in an explicit transaction.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        [outerLayer, filledInnerLayer].forEach { layer in
            layer.fillColor = shouldHighlight ? darkened.cgColor : color.cgColor
        }
        label.textColor = shouldHighlight ? .lightGray : .white
        CATransaction.commit()
    }

}
