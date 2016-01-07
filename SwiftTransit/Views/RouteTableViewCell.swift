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
    
    var stateConstraints = [State: [NSLayoutConstraint]]()

    @IBOutlet weak var rail: ScheduleRail!
    @IBOutlet weak var title: TransitLabel!
    @IBOutlet weak var subtitle: TransitLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Clear color set in IB
        rail.backgroundColor = UIColor.clearColor()
        
        // Set subtitle to always display as uppercase
        subtitle.uppercase = true
        
        establishConstraints()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: State transitions
    
    func transitionForVehiclesInTransit() -> () -> Void {
        return {
            self.backgroundColor = UIColor.darkGrayColor()
            self.title.hidden = true
            self.subtitle.textColor = UIColor.lightTextColor()
            self.subtitle.hidden = false
            self.stateConstraints[.VehiclesInTransit]!.forEach { $0.active = true }
            self.rail.showStation = false
            self.rail.showVehicle = true
        }
    }
        
    func transitionForEmptyStation() -> () -> Void {
        return {
            self.backgroundColor = UIColor.whiteColor()
            self.title.textColor = UIColor.darkTextColor()
            self.title.hidden = false
            self.subtitle.hidden = true
            self.stateConstraints[.EmptyStation]!.forEach { $0.active = true }
            self.rail.showStation = true
            self.rail.showVehicle = false
        }
    }
    
    func transitionForVehiclesAtStation() -> () -> Void {
        return {
            self.backgroundColor = UIColor.whiteColor()
            self.title.textColor = UIColor.darkTextColor()
            self.title.hidden = false
            self.subtitle.hidden = false
            self.stateConstraints[.VehiclesAtStation]!.forEach { $0.active = true }
            self.rail.showStation = true
            self.rail.showVehicle = true
        }
    }
    
    // Called once to populate state constraints table
    func establishConstraints() {
        stateConstraints[.VehiclesInTransit] = [
            NSLayoutConstraint(item: rail, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30.0),
            NSLayoutConstraint(item: subtitle, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .TopMargin, multiplier: 1.0, constant: -2.0)
        ]
        
        stateConstraints[.EmptyStation] = [
            NSLayoutConstraint(item: rail, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0),
            NSLayoutConstraint(item: title, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .TopMargin, multiplier: 1.0, constant: 1.0)
        ]
        
        stateConstraints[.VehiclesAtStation] = [
            NSLayoutConstraint(item: rail, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0),
            NSLayoutConstraint(item: title, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .TopMargin, multiplier: 1.0, constant: -5.0),
            NSLayoutConstraint(item: subtitle, attribute: .Top, relatedBy: .Equal, toItem: title,
                attribute: .Bottom, multiplier: 1.0, constant: 0)
        ]
    }

    // Wrap the transition function in layout calls
    func layout(transition: () -> Void) -> () -> Void {
        return {
            self.layoutIfNeeded()
            // Disable all constraints before adding new ones in transition()
            self.stateConstraints.forEach { $0.1.forEach { $0.active = false }}
            transition()
            self.layoutIfNeeded()
        }
    }
    
    func updateStateFromState(fromState: State, toState: State) {
        switch (toState) {
        case .VehiclesInTransit:
            UIView.animateWithDuration(0.25, animations: layout(transitionForVehiclesInTransit()))
        case .EmptyStation:
            UIView.animateWithDuration(0.25, animations: layout(transitionForEmptyStation()))
        case .VehiclesAtStation:
            UIView.animateWithDuration(0.25, animations: layout(transitionForVehiclesAtStation()))
        }
    }
    
    // MARK: Class functions

    class func determineStateForVehicles(vehicles: Bool, station: Bool) -> State? {
        switch (vehicles, station) {
        case (true, true):
            return State.VehiclesAtStation
        case (true, false):
            return State.VehiclesInTransit
        case (false, true):
            return State.EmptyStation
        case (false, false):
            return nil
        }
    }
    
    class func rowHeightForState(state: State) -> CGFloat {
        if state == .VehiclesInTransit {
            return 30.0
        } else {
            return 43.0
        }
    }
}
