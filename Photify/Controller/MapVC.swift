//
//  ViewController.swift
//  Photifiy
//
//  Created by Ketan Choyal on 14/12/18.
//  Copyright © 2018 Ketan Choyal. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
                
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
    }
}

extension MapVC : MKMapViewDelegate {
    
}

extension MapVC : CLLocationManagerDelegate {
    
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
}
