//
//  DroppablePin.swift
//  Photify
//
//  Created by Ketan Choyal on 20/12/18.
//  Copyright © 2018 Ketan Choyal. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin : NSObject, MKAnnotation {
    dynamic var coordinate : CLLocationCoordinate2D
    var identifier : String
    
    init(coordinate : CLLocationCoordinate2D, identifier : String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
