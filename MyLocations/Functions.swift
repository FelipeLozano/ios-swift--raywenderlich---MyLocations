//
//  Functions.swift
//  MyLocations
//
//  Created by Felipe Lozano on 20/04/16.
//  Copyright © 2016 FelipeCanayo. All rights reserved.
//

import Foundation
import Foundation
import Dispatch
func afterDelay(seconds: Double, closure: () -> ()) {
    let when = dispatch_time(DISPATCH_TIME_NOW,
                             Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when, dispatch_get_main_queue(), closure)
}
let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()
