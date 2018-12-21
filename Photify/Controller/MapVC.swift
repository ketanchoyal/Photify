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
import Alamofire

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeightConstriant: NSLayoutConstraint!
    @IBOutlet weak var pullUpViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    var regionRadius : Double = 1000
    var screenSize = UIScreen.main.bounds
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    
    var spinner : UIActivityIndicatorView?
    var progressLabel : UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView : UICollectionView?
    
    var imageUrlArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
    
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstriant.constant = 300
        
        if UIDevice().userInterfaceIdiom == .phone {
            let nativeHeight = UIScreen.main.nativeBounds.height
            if nativeHeight == 2436 || nativeHeight == 2688 || nativeHeight == 1792 {
                self.pullUpViewBottomConstraint.constant = 35
            }
        }
        //mapView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: self.view.frame.height - 300)
        mapView.frame.size.height = view.frame.height - 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.mapView.layoutIfNeeded()
        }
    }
    
    func retriveImageUrl(forAnnotation annotation : DroppablePin, handeler : @escaping(_ status : Bool) -> ()) {
        imageUrlArray.removeAll()

        Alamofire.request(flickerUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            
            for photo in photosDictArray {
                let photoUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                
                self.imageUrlArray.append(photoUrl)
            }
            handeler(true)
        }
    }
    
    @objc func animateViewDown() {
        self.hideCollectionView()
        pullUpViewHeightConstriant.constant = 0
        pullUpViewBottomConstraint.constant = 0
        mapView.frame.size.height = screenSize.height
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.mapView.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: (pullUpView.frame.height / 2) - ((spinner?.frame.height)!))
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 0.83203125)
        spinner?.startAnimating()
        collectionView!.addSubview(spinner!)
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        progressLabel?.textAlignment = .center
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 100, y: (pullUpView.frame.height / 2) - ((spinner?.frame.height)!) + 10, width: 200, height: 40)
        progressLabel?.textColor = #colorLiteral(red: 0.004859850742, green: 0.09608627111, blue: 0.5749928951, alpha: 0.83203125)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.text = "20/40 Photos Loaded"
        collectionView!.addSubview(progressLabel!)
    }
    
    func addCollectionView() {
        collectionView = UICollectionView(frame: pullUpView.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        
        pullUpView.addSubview(collectionView!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func removeLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    func hideCollectionView() {
        if collectionView != nil {
            collectionView?.isHidden = true
        }
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}

extension MapVC : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation { return nil }
        let pinDropped = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinDropped.animatesDrop = true
        pinDropped.pinTintColor = #colorLiteral(red: 0, green: 0.5008062124, blue: 1, alpha: 1)
        return pinDropped
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender : UITapGestureRecognizer) {
        //removeCollectionView()
        removeAnnotation()
        removeSpinner()
        removeLabel()

        animateViewUp()
        addCollectionView()
        addSwipe()
        addSpinner()
        addProgressLabel()
        
        let touchPoint = sender.location(in: mapView)
        let touchCordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion(center: touchCordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        retriveImageUrl(forAnnotation: annotation) { (success) in
            if success {
                print(self.imageUrlArray)
            }
        }
    }
    
    func removeAnnotation() {
        mapView.removeAnnotations(mapView.annotations)
    }
}

extension MapVC : CLLocationManagerDelegate {
    
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
    
}

extension MapVC : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath)
        
        return cell
    }
    
    
}
