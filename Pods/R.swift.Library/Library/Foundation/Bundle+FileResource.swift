//
//  Bundle+FileResource.swift
//  R.swift.Library
//
//  Created by Mathijs Kadijk on 10-01-16.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

public extension Bundle {
  /**
   Returns the file URL for the given resource (R.file.*).

   - parameter resource: The resource to get the file URL for (R.file.*).

   - returns: The file URL for the resource file (R.file.*) or nil if the file could not be located.
   */
  func url(forResource resource: FileResourceType) -> URL? {
    return url(forResource: resource.name, withExtension: resource.pathExtension)
  }

  /**
   Returns the full pathname for the resource (R.file.*).

   - parameter resource: The resource file to get the path for (R.file.*).

   - returns: The full pathname for the resource file (R.file.*) or nil if the file could not be located.
   */
  func path(forResource resource: FileResourceType) -> String? {
    return path(forResource: resource.name, ofType: resource.pathExtension)
  }
}
