//
//  VehicleViewController.swift
//  SwiftTransit
//
//  Created by Elliott Williams on 10/17/15.
//  Copyright © 2015 Elliott Williams. All rights reserved.
//

import UIKit
import QuartzCore

class VehicleViewController: UIViewController, SceneMediatedController {
    
    // MARK: Properties
    
    @IBOutlet weak var vehicleImageView: UIImageView!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    var _vehicle: VehicleViewModel!
    var _sceneMediator = SceneMediator.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Outline the bus
        vehicleImageView.layer.shadowColor = UIColor.blackColor().CGColor
        vehicleImageView.layer.shadowRadius = 2;
        
        // Set navigation bar name
        navigationBar.title = _vehicle.name
        
        // Center things
//        let centerVehicleImage = NSLayoutConstraint(item: vehicleImageView, attribute: NSLayoutAttribute.CenterX,
//            relatedBy: NSLayoutRelation.Equal,
//            toItem: self.view, attribute: NSLayoutAttribute.CenterX,
//                multiplier: 1.0, constant: 0.0)
//        self.view.addConstraint(centerVehicleImage)
    }
    
    func setVehicleModel(vehicle: Vehicle) {
        self._vehicle = VehicleViewModel(vehicle)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        _sceneMediator.sendMessagesForSegueWithIdentifier(segue.identifier, segue: segue, sender: sender)
    }

}
