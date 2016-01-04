//
//  RouteTableViewCell.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 12/31/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

    enum State {
        case VehiclesInTransit
        case EmptyStation
        case VehiclesAtStation
    }
    var state: RouteTableViewCell.State = .EmptyStation {
        didSet { updateStateFromState(oldValue, toState: self.state) }
    }
    
    var stateConstraints: [State: [NSLayoutConstraint]]!

    @IBOutlet weak var rail: ScheduleRail!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    var hasVehicle: Bool = false {
        didSet { rail.hasVehicle = self.hasVehicle }
    }
    var hasStation: Bool = false {
        didSet { rail.hasStation = self.hasStation }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Clear color set in IB
        rail.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func establishConstraints() {
        stateConstraints[.VehiclesInTransit] = [
            NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30.0),
            NSLayoutConstraint(item: rail, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30.0),
            NSLayoutConstraint(item: title, attribute: .TopMargin, relatedBy: .Equal, toItem: self.superview, attribute: .Top, multiplier: 1.0, constant: 4.0)
        ]
        
        stateConstraints[.EmptyStation] = [
            NSLayoutConstraint(item: self, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0),
            NSLayoutConstraint(item: rail, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0),
            NSLayoutConstraint(item: title, attribute: .TopMargin, relatedBy: .Equal, toItem: self.superview, attribute: .Top, multiplier: 1.0, constant: -3.0)
        ]
    }

    func updateStateFromState(fromState: State, toState: State) {
        switch (toState) {
        case .VehiclesInTransit:
            adjustToVehiclesInTransitFromState(fromState)
        }
    }
    
    func adjustToVehiclesInTransitFromState(fromState: State) {
        UIView.animateWithDuration(0.25) {
            self.layoutIfNeeded()
            self.backgroundColor = UIColor.darkGrayColor()
            self.removeConstraints(self.stateConstraints[fromState]!)
            self.addConstraints(self.stateConstraints[State.VehiclesInTransit]!)
        }
    }
}
