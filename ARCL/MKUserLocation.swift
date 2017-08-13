//
//  MKUserLocation.swift
//  ARCL
//
//  Created by levantAJ on 8/13/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import MapKit

extension MKUserLocation {
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        return MKMapItem(placemark: placemark)
    }
}
