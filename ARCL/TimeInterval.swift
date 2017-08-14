//
//  TimeInterval.swift
//  ARCL
//
//  Created by levantAJ on 8/14/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import UIKit

extension TimeInterval {
    var timeString: String {
        if self < 60 {
            return "\(Int(self)) sec"
        }
        if self < 3600 {
            return String(format: "%0.1f min", self/60)
        }
        if self == 3600 {
            return "an hour"
        }
        return String(format: "%0.1f hours", self/3600)
    }
}
