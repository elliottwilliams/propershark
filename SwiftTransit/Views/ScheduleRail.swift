//
//  ScheduleRail.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ScheduleRail: UIView {
    
    enum RailShape {
        case WestSouth
        case NorthWest
        case NorthSouth
        case WestEast
    }
    
    enum RailPathSegment {
        case Full
        case Entrance
        case Exit
    }
    
    // MARK: Properties
    
    var showVehicle: Bool {
        get { return !_vehicleLayer.hidden }
        set(newState) { setVehicleState(newState) }
    }
    var showStation: Bool {
        get { return !_stationLayer.hidden }
        set(newState) { setStationState(newState) }
    }
    var shape: RailShape = .NorthSouth
    var vehicleColor: UIColor? {
        get { return _vehicleColor }
        set { updateColor(newValue ?? _defaultVehicleColor) }
    }
    
    let _railColor = UIColor.lightGrayColor()
    let _stationLayer = CAShapeLayer()
    let _vehicleLayer = CAShapeLayer()
    let _pullDownVehicleLayer = CAShapeLayer()
    let _leftMargin = CGFloat(16.0) // Used to know how far offscreen to draw rails that end to the west
    let _vehicleDotRadius = CGFloat(8.0)
    let _vehicleStrokeWidth = CGFloat(3.0)
    let _defaultVehicleColor = UIColor.blueColor()
    
    var _width: CGFloat!
    var _height: CGFloat!
    var _vehicleColor: UIColor = UIColor.blueColor()
    var _hasLayout: Bool = false
    var _animationCallbacks: [CAAnimation: (anim: CAAnimation, finished: Bool) -> ()] = [:]
    
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
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    // When a resize occurs or when the view is first drawn, layoutSubviews is called and we can grab new width and height values
    override func layoutSubviews() {
        _width = self.frame.width
        _height = self.frame.height
        _hasLayout = true
        super.layoutSubviews()
    }
    
    // Add and configure layers
    func bootstrap() {
        self.layer.addSublayer(_stationLayer)
        self.layer.addSublayer(_vehicleLayer)
        self.layer.addSublayer(_pullDownVehicleLayer)
        
        self.layer.needsDisplayOnBoundsChange = true
        self.layer.sublayers!.forEach { $0.needsDisplayOnBoundsChange = true }
        
        self.layer.setNeedsDisplay() // Draw everying on initialization
    }
    
    override func displayLayer(layer: CALayer) {
        if !_hasLayout { // don't display if view hasn't been laid out
            return
        }
        // TODO: ensure that sublayers are cleared when the layer cache is refreshed
        drawRailOnLayer(layer as! CAShapeLayer) // layerClass() declares CAShapeLayer as this view's layer class, so this should always unwrap
        drawStationNode()
//        drawVehicle(_vehicleLayer)
//        drawVehicle(_pullDownVehicleLayer)
        _pullDownVehicleLayer.hidden = true
    }
    
    // MARK: Reusable drawing code
    
    func drawRailOnLayer(layer: CAShapeLayer) {
        let path = CGPathCreateMutable()
        drawRailPath(path, shape: self.shape, segment: .Full, width: _width, height: _height)
        
        layer.path = path
        layer.strokeColor = _railColor.CGColor
        layer.lineWidth = 2.0
        layer.fillColor = UIColor.clearColor().CGColor
    }
    
    func stationNodeIntersectionPoint() -> CGPoint {
        return CGPoint(x: self.frame.minX + _width/2, y: self.frame.minY + _height/2)
    }
    
    func drawStationNode() {
        if !showStation {
            return
        }
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, _width * 0.2, _height/2)
        CGPathAddLineToPoint(path, nil, _width * 0.8, _height/2)
        
        _stationLayer.path = path
        _stationLayer.strokeColor = _railColor.CGColor
        _stationLayer.lineWidth = 2.0
    }
    
    func drawVehicle(layer: CAShapeLayer) {
        let path = CGPathCreateMutable()
        let edge = _vehicleDotRadius*2
        CGPathAddEllipseInRect(path, nil, CGRectMake(0, 0, edge, edge))
//        CGPathAddArc(path, nil, _width/2, _height/2, _vehicleDotRadius, 0, CGFloat(2.0*M_PI), true)
        
        layer.path = path
        layer.frame = CGRectMake(_width/2 - _vehicleDotRadius, _height/2 - _vehicleDotRadius, edge, edge)
        layer.strokeColor = UIColor.snowColor().CGColor
        layer.lineWidth = _vehicleStrokeWidth
        layer.fillColor = _vehicleColor.CGColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    // Construct a path to draw the rail along and to send vehicles on based on shape, segment, and dimensions given. If a path is passed to this method, it will be modified with the requested rail path.
    func drawRailPath(path: CGMutablePathRef, shape: RailShape, segment: RailPathSegment, width: CGFloat, height: CGFloat) {
        // Get the current point of the path if it's not empty, which is used to draw relative to whatever's already on the path
        let c = (CGPathIsEmpty(path)) ? CGPoint(x: 0, y: 0) : CGPathGetCurrentPoint(path)
        if segment == .Entrance || segment == .Full {
            switch (shape) {
            case .NorthSouth:
                CGPathMoveToPoint(path, nil, width/2, c.y)
                CGPathAddLineToPoint(path, nil, width/2, c.y+height/2)
            case .WestEast:
                CGPathMoveToPoint(path, nil, -1*_leftMargin, c.y+height/2)
                CGPathAddLineToPoint(path, nil, width/2, c.y+height/2)
            case .NorthWest:
                CGPathMoveToPoint(path, nil, width/2, c.y)
                CGPathAddArc(path, nil, 0, c.y, width/2, 0, CGFloat(M_PI/4), false)
            case .WestSouth:
                CGPathMoveToPoint(path, nil, -1*_leftMargin, c.y+height/2)
                CGPathAddLineToPoint(path, nil, 0, c.y+height/2)
                CGPathAddArc(path, nil, 0, c.y+height, height/2, 0, CGFloat(M_PI/4), false)
            }
        }
        if segment == .Exit || segment == .Full {
            switch(shape) {
            case .NorthSouth:
                CGPathMoveToPoint(path, nil, width/2, c.y+height/2)
                CGPathAddLineToPoint(path, nil, width/2, c.y+height)
            case .WestEast:
                CGPathMoveToPoint(path, nil, width/2, c.y+height/2)
                CGPathAddLineToPoint(path, nil, width, c.y+height/2)
            case .NorthWest:
                CGPathMoveToPoint(path, nil, width/(2*sqrt(3)), c.y+width/(2*sqrt(3)))
                CGPathAddArc(path, nil, 0, c.y, width/2, CGFloat(M_PI/4), CGFloat(M_PI/2), false)
                CGPathAddLineToPoint(path, nil, -1*_leftMargin, c.y+height/2)
            case .WestSouth:
                CGPathMoveToPoint(path, nil, height/(2*sqrt(3)), c.y + height - height/(2*sqrt(3)))
                CGPathAddArc(path, nil, 0, c.y+height, height/2, CGFloat(M_PI/4), CGFloat(M_PI/2), false)
            }
        }
    }
    
    @available(*, deprecated=1.0, message="Use drawRailPath: instead")
    func railPath() -> (full: CGMutablePathRef, entrance: CGMutablePathRef, exit: CGMutablePathRef) {
        let paths = (CGPathCreateMutable(), CGPathCreateMutable(), CGPathCreateMutable())
        drawRailPath(paths.0, shape: self.shape, segment: .Full, width: _width, height: _height)
        drawRailPath(paths.1, shape: self.shape, segment: .Entrance, width: _width, height: _height)
        drawRailPath(paths.2, shape: self.shape, segment: .Exit, width: _width, height: _height)
        return paths
    }
    
    func entrancePoint() -> CGPoint {
        switch (self.shape) {
        case .NorthSouth, .NorthWest:
            return CGPoint(x: _width/2, y: 0)
        case .WestEast, .WestSouth:
            return CGPoint(x: -1*_leftMargin, y: _height/2)
        }
    }
    
    func exitPoint() -> CGPoint {
        switch (self.shape) {
        case .NorthSouth, .WestSouth:
            return CGPoint(x: _width/2, y: _height)
        case .WestEast:
            return CGPoint(x: _width, y: _height/2)
        case .NorthWest:
            return CGPoint(x: -1*_leftMargin, y: _height/2)
        }
    }
    
    func restingPoint() -> CGPoint {
        return CGPoint(x: _width/2, y: _height/2)
    }
    
    // MARK: Animation
    
    @available(*, deprecated=1.0)
    func animationForVehiclePosition(path: CGPathRef, withDelay delay: Double = 0.0) -> CAKeyframeAnimation {
        let anim = CAKeyframeAnimation(keyPath: "position")
        anim.path = path
        anim.fillMode = kCAFillModeBackwards
        anim.beginTime = delay
//        anim.duration = 0.25
        return anim
    }
    
    // A keyframe animation that changes visibility at the very end of the animation. This allows a visibility change to be grouped with other animations, and change at the end of the animation.
    func animationForHiddenness(shouldHide: Bool) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "hidden")
        anim.fromValue = shouldHide
        anim.toValue = shouldHide
        anim.fillMode = kCAFillModeBoth
        return anim
    }
    
    func animatePushDownToRailOfShape(shape: RailShape, height: CGFloat, completion: ((Bool) -> Void)? = nil) {
        let options = UIViewAnimationOptions.CurveEaseInOut
        UIView.animateWithDuration(0.25, delay: 0.0, options: options, animations: {
            let group = CAAnimationGroup()
            let hiddenAnim = self.animationForHiddenness(false)
            let positionAnim = CAKeyframeAnimation(keyPath: "position")
            
            let path = CGPathCreateMutable()
            self.drawRailPath(path, shape: self.shape, segment: .Exit, width: self._width, height: self._height)
            self.drawRailPath(path, shape: shape, segment: .Entrance, width: self._width, height: height)
            positionAnim.path = path
            
            group.animations = [positionAnim, hiddenAnim]
            self._vehicleLayer.addAnimation(group, forKey: "showVehicle")
        }, completion: completion)
    }
    
    func animatePullDown(completion: ((Bool) -> Void)? = nil) {
        let options = UIViewAnimationOptions.CurveEaseOut
        UIView.animateWithDuration(0.25, delay: 0.0, options: options, animations: {
            let group = CAAnimationGroup()
            let hiddenAnim = self.animationForHiddenness(false)
            let positionAnim = CAKeyframeAnimation(keyPath: "position")
            
            let path = CGPathCreateMutable()
            self.drawRailPath(path, shape: self.shape, segment: .Entrance, width: self._width, height: self._height)
            positionAnim.path = path
            
            group.animations = [positionAnim, hiddenAnim]
            self._pullDownVehicleLayer.addAnimation(group, forKey: "showVehicle")
        }, completion: completion)
    }
    
    // MARK: Setters and updaters
    
    // Set visibility of the vehicle and animate vehicle entrance/exit
    func setVehicleState(showVehicle: Bool) {
        UIView.animateWithDuration(0.0) {
            self._vehicleLayer.hidden = !showVehicle
        }
    }
    
    func setStationState(showStation: Bool) {
        _stationLayer.hidden = !showStation
    }
    
    func updateColor(newColor: UIColor) {
        _vehicleColor = newColor
        _vehicleLayer.fillColor = newColor.CGColor
        _pullDownVehicleLayer.fillColor = newColor.CGColor
    }

}
