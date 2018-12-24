//
//  PopVC.swift
//  Photify
//
//  Created by Ketan Choyal on 24/12/18.
//  Copyright © 2018 Ketan Choyal. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImageView: UIImageView!
    
    var passedImage : UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popImageView.image = passedImage
        
        addDoubleTap()
    }
    
    func initData(forImage image : UIImage) {
        self.passedImage = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func doubleTapped() {
        dismiss(animated: true, completion: nil)
    }

}
