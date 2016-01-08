//
//  RailVehicle.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 1/7/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit

class RailVehicle: UIView {
    
    var color: UIColor = UIColor.blueColor()

    let _vehicleDotRadius = CGFloat(8.0)
    let _vehicleStrokeWidth = CGFloat(3.0)
    
    static let width = CGFloat(22)
    static let height = CGFloat(22)
    
    override init(frame: CGRect) {
        let centered = RailVehicle.frameForPoint(CGPoint(x: frame.minX, y: frame.minY))
        super.init(frame: centered)
        self.layer.setNeedsDisplay()
    }
    
    convenience init(point: CGPoint) {
        self.init(frame: CGRectMake(point.x, point.y, 0, 0))
    }
    
    convenience init(frame: CGRect, color: UIColor?) {
        self.init(frame: frame)
        if color != nil {
            self.color = color!
        }
    }
    
    convenience init(point: CGPoint, color: UIColor?) {
        self.init(point: point)
        if color != nil {
            self.color = color!
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.setNeedsDisplay()
    }
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    static func frameForPoint(point: CGPoint) -> CGRect {
        return CGRectMake(point.x-(self.width/2), point.y-(self.height/2), self.width, self.height)
    }
    
    override func displayLayer(layer: CALayer) {
        drawVehicle(layer as! CAShapeLayer)
    }
    
    func drawVehicle(layer: CAShapeLayer) {
        layer.path = CGPathCreateWithEllipseInRect(self.bounds, nil)
        layer.strokeColor = UIColor.snowColor().CGColor
        layer.lineWidth = _vehicleStrokeWidth
        layer.fillColor = self.color.CGColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    func moveTo(coords: CGPoint, completion: ((Bool) -> Void)? = nil) {
        UIView.animateWithDuration(0.25, animations: {
            self.frame = RailVehicle.frameForPoint(coords)
        }, completion: completion)
    }
    
}