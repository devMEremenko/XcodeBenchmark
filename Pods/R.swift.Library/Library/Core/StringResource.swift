//
//  StringResource.swift
//  R.swift.Library
//
//  Created by Tom Lokhorst on 2016-04-23.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

public protocol StringResourceType {

  /// Key for the string
  var key: String { get }

  /// File in containing the string
  var tableName: String { get }

  /// Bundle this string is in
  var bundle: Bundle { get }

  /// Locales of the a localizable string
  var locales: [String] { get }
  
  /// Comment directly before and/or after the string, if any
  var comment: String? { get }
}

public struct StringResource: StringResourceType {

  /// Key for the string
  public let key: String

  /// File in containing the string
  public let tableName: String

  /// Bundle this string is in
  public let bundle: Bundle

  /// Locales of the a localizable string
  public let locales: [String]
  
  /// Comment directly before and/or after the string, if any
  public let comment: String?

  public init(key: String, tableName: String, bundle: Bundle, locales: [String], comment: String?) {
    self.key = key
    self.tableName = tableName
    self.bundle = bundle
    self.locales = locales
    self.comment = comment
  }
}
