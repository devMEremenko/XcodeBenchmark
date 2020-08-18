//
//  Identifier.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

/// Base protocol for all identifiers
public protocol IdentifierType: CustomStringConvertible {
  /// Identifier string
  var identifier: String { get }
}

extension IdentifierType {
  /// CustomStringConvertible implementation, returns the identifier
  public var description: String {
    return identifier
  }
}
