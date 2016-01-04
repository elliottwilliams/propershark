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
    }
    
    // MARK: Properties
    
    var hasVehicle: Bool = false {
        didSet { updateVehicleState() }
    }
    var hasStation: Bool = true {
        didSet { updateStationState() }
    }
    var type: ScheduleRail.RailType = .NorthSouth
    
    let _railColor = UIColor.lightGrayColor()
    let _stationLayer = CAShapeLayer()
    let _vehicleLayer = CAShapeLayer()
    
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
    
    // Add layers and draw everything
    func bootstrap() {
        _width = self.frame.width
        _height = self.frame.height
        self.layer.addSublayer(_stationLayer)
        self.layer.addSublayer(_vehicleLayer)
        
        drawRail(self.layer as! CAShapeLayer)
        drawStationNode()
    }
    
    // MARK: Reusable drawing code
    
    func drawRail(layer: CAShapeLayer) {
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, _width/2, 0)
        CGPathAddLineToPoint(path, nil, _width/2, _height)
        
        layer.path = path
        layer.strokeColor = _railColor.CGColor
        layer.lineWidth = 2.0
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
        _vehicleLayer.fillColor = UIColor.blueColor().CGColor
        _vehicleLayer.shadowOpacity = 0.5
    }
    
    // MARK: Setters and updaters
    
    func updateVehicleState() {
        _vehicleLayer.hidden = !hasVehicle
    }
    
    func updateStationState() {
        _stationLayer.hidden = !hasStation
    }

}
