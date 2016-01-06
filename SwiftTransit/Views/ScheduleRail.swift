//
//  ScheduleRail.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class ScheduleRail: UIView {
    
    enum RailType {
        case WestSouth
        case NorthWest
        case NorthSouth
        case WestEast
    }
    
    // MARK: Properties
    
    var hasVehicle: Bool = false {
        didSet { updateVehicleState() }
    }
    var hasStation: Bool = false {
        didSet { updateStationState() }
    }
    var type: RailType = .NorthSouth
    
    let _railColor = UIColor.lightGrayColor()
    let _stationLayer = CAShapeLayer()
    let _vehicleLayer = CAShapeLayer()
    let _leftMargin = CGFloat(16.0) // Used to know how far offscreen to draw rails that end to the west
    
    var _width: CGFloat!
    var _height: CGFloat!
    
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
    
    // Add and configure layers
    func bootstrap() {
        self.layer.addSublayer(_stationLayer)
        self.layer.addSublayer(_vehicleLayer)
        
        self.layer.needsDisplayOnBoundsChange = true
        self.layer.sublayers!.forEach { $0.needsDisplayOnBoundsChange = true }
        
        // Determine whether to display vehicle or station nodes
        updateVehicleState()
        updateStationState()
        
        self.layer.setNeedsDisplay() // Draw everying on initialization
    }
    
    override func displayLayer(layer: CALayer) {
        _width = self.frame.width
        _height = self.frame.height
        // TODO: ensure that sublayers are cleared when the layer cache is refreshed
        drawRailOnLayer(layer as! CAShapeLayer) // layerClass() declares CAShapeLayer as this view's layer class, so this should always unwrap
        drawStationNode()
        drawVehicle()
    }
    
    // MARK: Reusable drawing code
    
    func drawRailOnLayer(layer: CAShapeLayer) {
        let path = railPath()
        
        layer.path = path
        layer.strokeColor = _railColor.CGColor
        layer.lineWidth = 2.0
        layer.fillColor = UIColor.clearColor().CGColor
    }
    
    func drawStationNode() {
        if !hasStation {
            return
        }
        
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, _width * 0.2, _height/2)
        CGPathAddLineToPoint(path, nil, _width * 0.8, _height/2)
        
        _stationLayer.path = path
        _stationLayer.strokeColor = _railColor.CGColor
        _stationLayer.lineWidth = 2.0
    }
    
    func drawVehicle() {
        let path = CGPathCreateMutable()
        CGPathAddArc(path, nil, _width/2, _height/2, 5.0, 0, CGFloat(2.0*M_PI), true)
        
        // TODO: fancier coloring
        _vehicleLayer.path = path
        _vehicleLayer.strokeColor = UIColor.whiteColor().CGColor
        _vehicleLayer.lineWidth = 2.0
        _vehicleLayer.fillColor = UIColor.blueColor().CGColor // TODO: use route color
        _vehicleLayer.shadowOpacity = 0.3
        _vehicleLayer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    func railPath() -> CGMutablePathRef {
        let path = CGPathCreateMutable()
        
        switch (self.type) {
        case .NorthSouth:
            CGPathMoveToPoint(path, nil, _width/2, 0)
            CGPathAddLineToPoint(path, nil, _width/2, _height)
        case .WestEast:
            CGPathMoveToPoint(path, nil, -1*_leftMargin, _height/2)
            CGPathAddLineToPoint(path, nil, _width, _height/2)
        case .NorthWest:
            CGPathMoveToPoint(path, nil, _width/2, 0)
            CGPathAddArc(path, nil, 0, 0, _width/2, 0, CGFloat(M_PI/2), false)
            CGPathAddLineToPoint(path, nil, -1*_leftMargin, _height/2)
        case .WestSouth:
            CGPathMoveToPoint(path, nil, -1*_leftMargin, _height/2)
            CGPathAddLineToPoint(path, nil, 0, _height/2)
            CGPathAddArc(path, nil, 0, _height, _height/2, 0, CGFloat(M_PI/2), false)
        }
        return path
    }
    
    // MARK: Setters and updaters
    
    func updateVehicleState() {
        _vehicleLayer.hidden = !hasVehicle
    }
    
    func updateStationState() {
        _stationLayer.hidden = !hasStation
    }

}
