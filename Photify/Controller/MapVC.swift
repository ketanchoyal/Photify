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
import AlamofireImage

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
    var imageArray = [UIImage]()
    
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
        pullUpViewHeightConstriant.constant = view.frame.height * 0.6
        
        if UIDevice().userInterfaceIdiom == .phone {
            let nativeHeight = UIScreen.main.nativeBounds.height
            if nativeHeight == 2436 || nativeHeight == 2688 || nativeHeight == 1792 {
                self.pullUpViewBottomConstraint.constant = 35
            }
        }
        //mapView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: self.view.frame.height - 300)
        mapView.frame.size.height = view.frame.height * 0.4
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.mapView.layoutIfNeeded()
        }
    }
    
    func retriveImageUrl(forAnnotation annotation : DroppablePin, handeler : @escaping(_ status : Bool) -> ()) {
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
    
    func retriveImage(handler : @escaping (_ complete : Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                
                self.progressLabel?.text = "\(self.imageArray.count)/\(self.imageUrlArray.count) Photos Loaded"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            }
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadTask, downloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadTask.forEach({ $0.cancel() })
        }
    }
    
    @objc func animateViewDown() {
        
        pullUpViewHeightConstriant.constant = 0
        pullUpViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.4) {
            self.mapView.frame.size.height = self.screenSize.height
            self.view.layoutIfNeeded()
            //self.mapView.layoutIfNeeded()
        }
        cancelAllSessions()
        self.hideCollectionView()
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
        progressLabel?.font = UIFont(name: "Avenir Next", size: 15)
        progressLabel?.text = "?/? Photos Loaded"
        collectionView!.addSubview(progressLabel!)
    }
    
    func addCollectionView() {
        collectionView = UICollectionView(frame: pullUpView.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
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
        cancelAllSessions()
        removeAnnotation()
        removeSpinner()
        removeLabel()
        
        imageArray.removeAll()
        imageUrlArray.removeAll()
        collectionView?.reloadData()

        animateViewUp()
        //animateViewUp()
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
                self.retriveImage(handler: { (success) in
                    if success {
                        self.removeLabel()
                        self.removeSpinner()
                        self.collectionView?.reloadData()
                    }
                })
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
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        
        return cell
    }
    
    
}
