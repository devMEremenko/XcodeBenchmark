//
//  ReuseIdentifierProtocol.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

/// Reuse identifier protocol
public protocol ReuseIdentifierType: IdentifierType {
  /// Type of this reuseable
  associatedtype ReusableType
}

/// Reuse identifier
public struct ReuseIdentifier<Reusable>: ReuseIdentifierType {
  /// Type of this reuseable
  public typealias ReusableType = Reusable

  /// String identifier of this reusable
  public let identifier: String

  /**
   Create a new ReuseIdentifier based on the string identifier
   
   - parameter identifier: The string identifier for this reusable

   - returns: A new ReuseIdentifier
  */
  public init(identifier: String) {
    self.identifier = identifier
  }
}
