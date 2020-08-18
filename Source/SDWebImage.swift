//
// SDWebImage.swift
// XcodeBenchmark
//
// Created on 18.08.2020.
//

import SDWebImage

public extension UIImageView {
    
    func downloadImage() {
        setImageWith(URL(string: "google.com")!)
    }
}

