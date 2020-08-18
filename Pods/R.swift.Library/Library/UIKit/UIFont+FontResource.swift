//
//  UIFont+FontResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 06-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation
import UIKit

public extension UIFont {
  /**
   Creates and returns a font object for the specified font resource (R.font.*) and size.

   - parameter resource: The font resource (R.font.*) for the specific font to load
   - parameter size: The size (in points) to which the font is scaled. This value must be greater than 0.0.

   - returns: A font object of the specified font resource and size.
   */
  convenience init?(resource: FontResourceType, size: CGFloat) {
    self.init(name: resource.fontName, size: size)
  }
}
