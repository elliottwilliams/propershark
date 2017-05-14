//
//  RailVehicle.swift
//  Proper
//
//  Created by Elliott Williams on 1/7/16.
//  Copyright © 2016 Elliott Williams. All rights reserved.
//

import UIKit
import CoreLocation

class RailVehicle: UIView {
    
    var color: UIColor = UIColor.blue
    var vehicle: Vehicle?

    let _vehicleDotRadius = CGFloat(8.0)
    let _vehicleStrokeWidth = CGFloat(3.0)
    
    static let width = CGFloat(22)
    static let height = CGFloat(22)
    static let offset = CGFloat(5.5) // distance between overlapping vehicles
    static let baseZPosition = CGFloat(20)
    
    override init(frame: CGRect) {
        let centered = RailVehicle.frameForPoint(CGPoint(x: frame.minX, y: frame.minY))
        super.init(frame: centered)
        self.layer.zPosition = RailVehicle.baseZPosition
        self.layer.setNeedsDisplay()
    }
    
    convenience init(point: CGPoint) {
        self.init(frame: CGRect(x: point.x, y: point.y, width: 0, height: 0))
    }
    
    convenience init(frame: CGRect, vehicle: Vehicle, on route: Route) {
        self.init(frame: frame)
        self.vehicle = vehicle
        self.color = route.color ?? UIColor.blue
    }
    
    convenience init(point: CGPoint, vehicle: Vehicle, on route: Route) {
        self.init(point: point)
        self.vehicle = vehicle
        self.color = route.color ?? UIColor.blue
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.zPosition = RailVehicle.baseZPosition
        self.layer.setNeedsDisplay()
    }
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    static func frame(for point: CGPoint) -> CGRect {
        return CGRect(x: point.x-(self.width/2), y: point.y-(self.height/2), width: self.width, height: self.height)
    }
    
    override func display(_ layer: CALayer) {
        drawVehicle(onto: layer as! CAShapeLayer)
    }
    
    func drawVehicle(onto layer: CAShapeLayer) {
        layer.path = CGPath(ellipseIn: self.bounds, transform: nil)
        layer.strokeColor = UIColor.snowColor().cgColor
        layer.lineWidth = _vehicleStrokeWidth
        layer.fillColor = self.color.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
    }
    
    func moveTo(_ coords: CGPoint, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.frame = RailVehicle.frame(for: coords)
        }, completion: completion)
    }
    
    // TODO: this might belong on the vehicle model, since it's quite general purpose
    func isNear(station: Station) -> Bool {
        // A station may have been created from a stub model, so we need to make sure it has a position.
        guard let vehicle = self.vehicle,
        let vehiclePosition = vehicle.position,
        let stationPosition = station.position
        else { return false }

        let a = CLLocation(point: vehiclePosition)
        let b = CLLocation(point: stationPosition)
        return a.distance(from: b) < 10.0
    }
    
}
