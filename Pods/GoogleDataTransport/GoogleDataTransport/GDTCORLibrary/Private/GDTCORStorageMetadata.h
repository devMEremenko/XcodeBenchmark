// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageSizeBytes.h"

NS_ASSUME_NONNULL_BEGIN

/// A model object that contains metadata about the current state of the SDK's storage container.
@interface GDTCORStorageMetadata : NSObject

/// The number of bytes the event cache is consuming in storage.
@property(nonatomic, readonly) GDTCORStorageSizeBytes currentCacheSize;

/// The maximum number of bytes that the event cache may consume in storage.
@property(nonatomic, readonly) GDTCORStorageSizeBytes maxCacheSize;

/// Creates a storage metadata object with the provided information.
/// @param currentCacheSize The current number of bytes the event cache is consuming.
/// @param maxCacheSize The current maximum capacity (in bytes) that the event cache may consume.
+ (instancetype)metadataWithCurrentCacheSize:(GDTCORStorageSizeBytes)currentCacheSize
                                maxCacheSize:(GDTCORStorageSizeBytes)maxCacheSize;

/// This API is unavailable.
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
