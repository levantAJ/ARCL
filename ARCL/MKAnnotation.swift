//
//  MKAnnotation.swift
//  ARCL
//
//  Created by levantAJ on 8/13/17.
//  Copyright © 2017 levantAJ. All rights reserved.
//

import MapKit

extension MKAnnotation {
    var mapItem: MKMapItem {
        let placemark = MKPlacemark(coordinate: coordinate)
        return MKMapItem(placemark: placemark)
    }
}
