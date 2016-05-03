//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Felipe Lozano on 02/05/16.
//  Copyright © 2016 FelipeCanayo. All rights reserved.
//

import Foundation
import UIKit
class MyTabBarController: UITabBarController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    override func childViewControllerForStatusBarStyle() ->
        UIViewController? {
            return nil
    }
}
