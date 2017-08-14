//
//  CLLocationDistance.swift
//  ARCL
//
//  Created by levantAJ on 8/14/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import MapKit

extension CLLocationDistance {
    var distanceString: String {
        if self >= 1000 {
            return String(format: "%0.2f km", self/1000.0)
        }
        return String(format: "%0.2f m", self)
    }
}
