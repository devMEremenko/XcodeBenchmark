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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

@implementation GDTCORMetrics

- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                          collectionEndDate:(NSDate *)collectionEndDate
                           logSourceMetrics:(GDTCORLogSourceMetrics *)logSourceMetrics
                           currentCacheSize:(GDTCORStorageSizeBytes)currentCacheSize
                               maxCacheSize:(GDTCORStorageSizeBytes)maxCacheSize
                                   bundleID:(NSString *)bundleID {
  self = [super init];
  if (self) {
    _collectionStartDate = [collectionStartDate copy];
    _collectionEndDate = [collectionEndDate copy];
    _logSourceMetrics = logSourceMetrics;
    _currentCacheSize = currentCacheSize;
    _maxCacheSize = maxCacheSize;
    _bundleID = [bundleID copy];
  }
  return self;
}

+ (instancetype)metricsWithMetricsMetadata:(GDTCORMetricsMetadata *)metricsMetadata
                           storageMetadata:(GDTCORStorageMetadata *)storageMetadata {
  // The window of collection ends at the time of creating the metrics object.
  NSDate *collectionEndDate = [NSDate date];
  // The main bundle ID is associated with the created metrics.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"";

  return [[GDTCORMetrics alloc] initWithCollectionStartDate:metricsMetadata.collectionStartDate
                                          collectionEndDate:collectionEndDate
                                           logSourceMetrics:metricsMetadata.logSourceMetrics
                                           currentCacheSize:storageMetadata.currentCacheSize
                                               maxCacheSize:storageMetadata.maxCacheSize
                                                   bundleID:bundleID];
}

#pragma mark - Equality

- (BOOL)isEqualToMetrics:(GDTCORMetrics *)otherMetrics {
  return [self.collectionStartDate isEqualToDate:otherMetrics.collectionStartDate] &&
         [self.collectionEndDate isEqualToDate:otherMetrics.collectionEndDate] &&
         [self.logSourceMetrics isEqualToLogSourceMetrics:otherMetrics.logSourceMetrics] &&
         [self.bundleID isEqualToString:otherMetrics.bundleID] &&
         self.currentCacheSize == otherMetrics.currentCacheSize &&
         self.maxCacheSize == otherMetrics.maxCacheSize;
}

- (BOOL)isEqual:(nullable id)object {
  if (object == nil) {
    return NO;
  }

  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self isEqualToMetrics:(GDTCORMetrics *)object];
}

- (NSUInteger)hash {
  return [self.collectionStartDate hash] ^ [self.collectionEndDate hash] ^
         [self.logSourceMetrics hash] ^ [self.bundleID hash] ^ [@(self.currentCacheSize) hash] ^
         [@(self.maxCacheSize) hash];
}

#pragma mark - Description

- (NSString *)description {
  return [NSString
      stringWithFormat:
          @"%@ {\n\tcollectionStartDate: %@,\n\tcollectionEndDate: %@,\n\tcurrentCacheSize: "
          @"%llu,\n\tmaxCacheSize: %llu,\n\tbundleID: %@,\n\tlogSourceMetrics: %@}\n",
          [super description], self.collectionStartDate, self.collectionEndDate,
          self.currentCacheSize, self.maxCacheSize, self.bundleID, self.logSourceMetrics];
}

@end
