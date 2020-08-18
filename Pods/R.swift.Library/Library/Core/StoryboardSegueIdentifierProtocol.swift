//
//  StoryboardSegueIdentifierProtocol.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

/// Segue identifier protocol
public protocol StoryboardSegueIdentifierType: IdentifierType {
  /// Type of the segue itself
  associatedtype SegueType

  /// Type of the source view controller
  associatedtype SourceType

  /// Type of the destination view controller
  associatedtype DestinationType
}

/// Segue identifier
public struct StoryboardSegueIdentifier<Segue, Source, Destination>: StoryboardSegueIdentifierType {
  /// Type of the segue itself
  public typealias SegueType = Segue

  /// Type of the source view controller
  public typealias SourceType = Source

  /// Type of the destination view controller
  public typealias DestinationType = Destination

  /// Identifier string of this segue
  public let identifier: String

  /**
   Create a new identifier based on the identifier string
   
   - returns: A new StoryboardSegueIdentifier
  */
  public init(identifier: String) {
    self.identifier = identifier
  }

  /// Create a new StoryboardSegue based on the identifier and source view controller
  public func storyboardSegue(withSource source: Source)
    -> StoryboardSegue<Segue, Source, Destination>
  {
    return StoryboardSegue(identifier: self, source: source)
  }
}

/// Typed segue information
public struct TypedStoryboardSegueInfo<Segue, Source, Destination>: StoryboardSegueIdentifierType {
  /// Type of the segue itself
  public typealias SegueType = Segue

  /// Type of the source view controller
  public typealias SourceType = Source

  /// Type of the destination view controller
  public typealias DestinationType = Destination

  /// Segue destination view controller
  public let destination: Destination

  /// Segue identifier
  public let identifier: String

  /// The original segue
  public let segue: Segue

  /// Segue source view controller
  public let source: Source
}

/// Segue with identifier and source view controller
public struct StoryboardSegue<Segue, Source, Destination> {
  /// Identifier of this segue
  public let identifier: StoryboardSegueIdentifier<Segue, Source, Destination>

  /// Segue source view controller
  public let source: Source

  /**
   Create a new segue based on the identifier and source view controller

   - returns: A new StoryboardSegue
   */
  public init(identifier: StoryboardSegueIdentifier<Segue, Source, Destination>, source: Source) {
    self.identifier = identifier
    self.source = source
  }
}
