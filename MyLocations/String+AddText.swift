//
//  String+AddText.swift
//  MyLocations
//
//  Created by Felipe Lozano on 02/05/16.
//  Copyright © 2016 FelipeCanayo. All rights reserved.
//

import Foundation
extension String {
    mutating func addText(text: String?, withSeparator separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}