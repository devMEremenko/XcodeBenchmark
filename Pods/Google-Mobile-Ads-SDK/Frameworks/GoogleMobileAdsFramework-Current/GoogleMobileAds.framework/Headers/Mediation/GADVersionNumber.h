//
//  GADVersionNumber.h
//  Google Mobile Ads SDK
//
//  Copyright 2018 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Version number information.
typedef struct GADVersionNumber GADVersionNumber;

/// Version number information.
struct GADVersionNumber {
  /// Major version.
  NSInteger majorVersion;
  /// Minor version.
  NSInteger minorVersion;
  /// Patch version.
  NSInteger patchVersion;
};
