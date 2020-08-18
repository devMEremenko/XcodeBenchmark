//
//  NibResource.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

/// Represents a nib file on disk
public protocol NibResourceType {

  /// Bundle this nib is in or nil for main bundle
  var bundle: Bundle { get }

  /// Name of the nib file on disk
  var name: String { get }
}
