//
//  UIStoryboard+StoryboardResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 07-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

#if !os(watchOS)
import UIKit

public extension UIStoryboard {
  /**
   Creates and returns a storyboard object for the specified storyboard resource (R.storyboard.*) file.

   - parameter resource: The storyboard resource (R.storyboard.*) for the specific storyboard to load

   - returns: A storyboard object for the specified file. If no storyboard resource file matching name exists, an exception is thrown with description: `Could not find a storyboard named 'XXXXXX' in bundle....`
   */
  convenience init(resource: StoryboardResourceType) {
    self.init(name: resource.name, bundle: resource.bundle)
  }
}
#endif
