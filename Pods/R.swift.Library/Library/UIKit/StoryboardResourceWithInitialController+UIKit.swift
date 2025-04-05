//
//  StoryboardResourceWithInitialController+UIKit.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 07-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

#if !os(watchOS)
import Foundation
import UIKit

public extension StoryboardResourceWithInitialControllerType {
  /**
   Instantiates and returns the initial view controller in the view controller graph.

   - returns: The initial view controller in the storyboard.
   */
  func instantiateInitialViewController() -> InitialController? {
    return UIStoryboard(resource: self).instantiateInitialViewController() as? InitialController
  }
}
#endif
