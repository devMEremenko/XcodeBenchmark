//
//  UIImage+ImageResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 11-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import UIKit

public extension UIImage {

  #if os(iOS) || os(tvOS)
  /**
   Returns the image from this resource (R.image.*) that is compatible with the trait collection.

   - parameter resource: The resource you want the image of (R.image.*)
   - parameter traitCollection: Traits that describe the desired image to retrieve, pass nil to use traits that describe the main screen.

   - returns: An image that exactly or best matches the desired traits with the given resource (R.image.*), or nil if no suitable image was found.
  */
  convenience init?(resource: ImageResourceType, compatibleWith traitCollection: UITraitCollection? = nil) {
    self.init(named: resource.name, in: resource.bundle, compatibleWith: traitCollection)
  }
  #endif

  #if os(watchOS)
  /**
   Returns the image from this resource (R.image.*) that is compatible with the trait collection.

   - parameter resource: The resource you want the image of (R.image.*)

   - returns: An image that exactly or best matches the desired traits with the given resource (R.image.*), or nil if no suitable image was found.
   */
  convenience init?(resource: ImageResourceType) {
    self.init(named: resource.name)
  }
  #endif
}
