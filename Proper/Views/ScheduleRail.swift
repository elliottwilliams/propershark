//
//  ScheduleRail.swift
//  Proper
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ScheduleRail: UIView {
    
    enum RailShape {
        case southwest
        case northwest
        case vertical
        case horizontal
    }
    
    enum RailPathSegment {
        case full
        case entrance
        case exit
    }
    
    // MARK: Properties
    
    var showStation: Bool {
        get { return !_stationLayer.isHidden }
        set(newState) { setStationState(newState) }
    }
    var shape: RailShape = .vertical {
        didSet { self.setNeedsDisplay() }
    }
    
    let _railColor = UIColor.lightGray
    let _stationLayer = CAShapeLayer()
    let _leftMargin = CGFloat(16.0) // Used to know how far offscreen to draw rails that end to the west
    
    var _width: CGFloat!
    var _height: CGFloat!
    var _hasLayout: Bool = false
    var _animationCallbacks: [CAAnimation: (_ anim: CAAnimation, _ finished: Bool) -> ()] = [:]
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bootstrap()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        bootstrap()
    }
    
    // Use a shape layer as the base layer of this class
    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    // When a resize occurs or when the view is first drawn, layoutSubviews is called and we can grab new width and height values
    override func layoutSubviews() {
        _width = self.frame.width
        _height = self.frame.height
        _hasLayout = true
        self.layer.setNeedsDisplay() // resizes mean we need to re-draw the rail
        super.layoutSubviews()
    }
    
    // Add and configure layers
    func bootstrap() {
        self.layer.addSublayer(_stationLayer)
        self.layer.needsDisplayOnBoundsChange = true
        self.layer.sublayers!.forEach { $0.needsDisplayOnBoundsChange = true }
        
        self.layer.setNeedsDisplay() // Draw everying on initialization
    }
    
    override func display(_ layer: CALayer) {
        if !_hasLayout { // don't display if view hasn't been laid out
            return
        }
        drawRail(on: layer as! CAShapeLayer) // layerClass() declares CAShapeLayer as this view's layer class, so this should always unwrap
        drawStationNode()
    }
    
    // MARK: Reusable drawing code
    
    func drawRail(on layer: CAShapeLayer) {
        let path = CGMutablePath()
        drawRailPath(path, shape: self.shape, segment: .full, width: _width, height: _height)
        
        layer.path = path
        layer.strokeColor = _railColor.cgColor
        layer.lineWidth = 2.0
        layer.fillColor = UIColor.clear.cgColor
    }
    
    func stationNodeIntersectionPoint() -> CGPoint {
        return CGPoint(x: self.frame.minX + _width/2, y: self.frame.minY + _height/2)
    }
    
    func drawStationNode() {
        if !showStation {
            return
        }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: _width * 0.2, y: _height / 2))
        path.addLine(to: CGPoint(x: _width * 0.8, y: _height/2))
        
        _stationLayer.path = path
        _stationLayer.strokeColor = _railColor.cgColor
        _stationLayer.lineWidth = 2.0
    }
    
    // Construct a path to draw the rail along and to send vehicles on based on shape, segment, and dimensions given. If a path is passed to this method, it will be modified with the requested rail path.
    func drawRailPath(_ path: CGMutablePath, shape: RailShape, segment: RailPathSegment, width: CGFloat, height: CGFloat) {
        // Get the current point of the path if it's not empty, which is used to draw relative to whatever's already on the path
        let c = (path.isEmpty) ? CGPoint(x: 0, y: 0) : path.currentPoint
        if segment == .entrance || segment == .full {
            switch (shape) {
            case .vertical:
                path.move(to: CGPoint(x: width/2, y: c.y))
                path.addLine(to: CGPoint(x: width/2, y: c.y+height/2))
            case .horizontal:
                path.move(to: CGPoint(x: -1*_leftMargin, y: c.y+height/2))
                path.addLine(to: CGPoint(x: width/2, y: c.y+height/2))
            case .northwest:
                path.move(to: CGPoint(x: width/2, y: c.y))
                path.addArc(center: CGPoint(x: 0, y: c.y), radius: width/2,
                            startAngle: 0, endAngle: .pi/4, clockwise: false)
            case .southwest:
                path.move(to: CGPoint(x: -1*_leftMargin, y: c.y+height/2))
                path.addLine(to: CGPoint(x: 0, y: c.y+height/2))
                path.addArc(center: CGPoint(x: 0, y: c.y+height), radius: height/2,
                            startAngle: 0, endAngle: .pi/4, clockwise: false)
            }
        }
        if segment == .exit || segment == .full {
            switch(shape) {
            case .vertical:
                path.move(to: CGPoint(x: width/2, y: c.y+height/2))
                path.addLine(to: CGPoint(x: width/2, y: c.y+height))
            case .horizontal:
                path.move(to: CGPoint(x: width/2, y: c.y+height/2))
                path.addLine(to: CGPoint(x: width, y: c.y+height/2))
            case .northwest:
                // AddArc moves to the proper starting point automatically, so we don't need to mess with MoveToPoint or do any trigonometry
                path.addArc(center: CGPoint(x: 0, y: c.y), radius: width/2,
                            startAngle: .pi/4, endAngle: .pi/4, clockwise: false)
                path.addLine(to: CGPoint(x: -1*_leftMargin, y: c.y+height/2))
            case .southwest:
                path.addArc(center: CGPoint(x: 0, y: c.y+height), radius: height/2,
                            startAngle: .pi/4, endAngle: .pi/4, clockwise: false)
            }
        }
    }

    func entrancePoint() -> CGPoint {
        switch (self.shape) {
        case .vertical, .northwest:
            return CGPoint(x: _width/2, y: 0)
        case .horizontal, .southwest:
            return CGPoint(x: -1*_leftMargin, y: _height/2)
        }
    }
    
    func exitPoint() -> CGPoint {
        switch (self.shape) {
        case .vertical, .southwest:
            return CGPoint(x: _width/2, y: _height)
        case .horizontal:
            return CGPoint(x: _width, y: _height/2)
        case .northwest:
            return CGPoint(x: -1*_leftMargin, y: _height/2)
        }
    }
    
    func restingPoint() -> CGPoint {
        return CGPoint(x: _width/2, y: _height/2)
    }
    
    // MARK: Setters and updaters
    
    func setStationState(_ showStation: Bool) {
        _stationLayer.isHidden = !showStation
    }
    

}
