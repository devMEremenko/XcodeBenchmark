//
//  StoryboardResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 07-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

public protocol StoryboardResourceType {

  /// Bundle this storyboard is in
  var bundle: Bundle { get }

  /// Name of the storyboard file on disk
  var name: String { get }
}

public protocol StoryboardResourceWithInitialControllerType: StoryboardResourceType {

  /// Type of the inital controller
  associatedtype InitialController
}
