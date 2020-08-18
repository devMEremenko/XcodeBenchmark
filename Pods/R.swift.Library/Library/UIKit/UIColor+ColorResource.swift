//
//  UIColor+ColorResource.swift
//  R.swift.Library
//
//  Created by Tom Lokhorst on 2017-06-06.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import UIKit

@available(iOS 11.0, *)
@available(tvOS 11.0, *)
public extension UIColor {

  #if os(iOS) || os(tvOS)
  /**
   Returns the color from this resource (R.color.*) that is compatible with the trait collection.

   - parameter resource: The resource you want the image of (R.color.*)
   - parameter traitCollection: Traits that describe the desired color to retrieve, pass nil to use traits that describe the main screen.

   - returns: A color that exactly or best matches the desired traits with the given resource (R.color.*), or nil if no suitable color was found.
   */
  convenience init?(resource: ColorResourceType, compatibleWith traitCollection: UITraitCollection? = nil) {
    self.init(named: resource.name, in: resource.bundle, compatibleWith: traitCollection)
  }
  #endif

  #if os(watchOS)
  /**
   Returns the color from this resource (R.color.*) that is compatible with the trait collection.

   - parameter resource: The resource you want the image of (R.color.*)

   - returns: A color that exactly or best matches the desired traits with the given resource (R.color.*), or nil if no suitable color was found.
   */
  @available(watchOSApplicationExtension 4.0, *)
  convenience init?(resource: ColorResourceType) {
    self.init(named: resource.name)
  }
  #endif
}
