//
//  Constants.swift
//  Photify
//
//  Created by Ketan Choyal on 21/12/18.
//  Copyright © 2018 Ketan Choyal. All rights reserved.
//

import Foundation

let API_KEY = "e0ee3b646bf9647645928dc76cb634a1"

func flickerUrl(forApiKey apikey : String, withAnnotation annotation : DroppablePin, andNumberOfPhotos number : Int) -> String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apikey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    
    return url
}
