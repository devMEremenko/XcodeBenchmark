//
// Google.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import GoogleMaps
import GooglePlaces
import GoogleMobileAds
import GoogleSignIn

public func printGoogle() {
    print(GMSMarker())
    print(GMSPath())
    
    print(GMSAddress())
    print(GADBannerView())
    
    print(GIDSignIn.sharedInstance)
}

public extension GMSMarker {
    
    func makeSomething() {
        print("Something")
    }
}
