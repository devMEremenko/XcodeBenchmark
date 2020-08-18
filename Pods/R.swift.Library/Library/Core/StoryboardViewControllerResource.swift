//
//  StoryboardViewControllerResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 13-03-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

public protocol StoryboardViewControllerResourceType: IdentifierType {
  associatedtype ViewControllerType
}

public struct StoryboardViewControllerResource<ViewController>: StoryboardViewControllerResourceType {
  public typealias ViewControllerType = ViewController

  /// Storyboard identifier of this view controller
  public let identifier: String

  public init(identifier: String) {
    self.identifier = identifier
  }
}
