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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"

static NSString *const kCollectionStartDate = @"collectionStartDate";
static NSString *const kLogSourceMetrics = @"logSourceMetrics";

@implementation GDTCORMetricsMetadata

+ (instancetype)metadataWithCollectionStartDate:(NSDate *)collectedSinceDate
                               logSourceMetrics:(GDTCORLogSourceMetrics *)logSourceMetrics {
  return [[self alloc] initWithCollectionStartDate:collectedSinceDate
                                  logSourceMetrics:logSourceMetrics];
}

- (instancetype)initWithCollectionStartDate:(NSDate *)collectionStartDate
                           logSourceMetrics:(GDTCORLogSourceMetrics *)logSourceMetrics {
  self = [super init];
  if (self) {
    _collectionStartDate = [collectionStartDate copy];
    _logSourceMetrics = logSourceMetrics;
  }
  return self;
}

#pragma mark - Equality

- (BOOL)isEqualToMetricsMetadata:(GDTCORMetricsMetadata *)otherMetricsMetadata {
  return [self.collectionStartDate isEqualToDate:otherMetricsMetadata.collectionStartDate] &&
         [self.logSourceMetrics isEqualToLogSourceMetrics:otherMetricsMetadata.logSourceMetrics];
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

  return [self isEqualToMetricsMetadata:(GDTCORMetricsMetadata *)object];
}

- (NSUInteger)hash {
  return [self.collectionStartDate hash] ^ [self.logSourceMetrics hash];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  NSDate *collectionStartDate = [coder decodeObjectOfClass:[NSDate class]
                                                    forKey:kCollectionStartDate];
  GDTCORLogSourceMetrics *logSourceMetrics =
      [coder decodeObjectOfClass:[GDTCORLogSourceMetrics class] forKey:kLogSourceMetrics];

  if (!collectionStartDate || !logSourceMetrics ||
      ![collectionStartDate isKindOfClass:[NSDate class]] ||
      ![logSourceMetrics isKindOfClass:[GDTCORLogSourceMetrics class]]) {
    // If any of the fields are corrupted, the initializer should fail.
    return nil;
  }

  return [self initWithCollectionStartDate:collectionStartDate logSourceMetrics:logSourceMetrics];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.collectionStartDate forKey:kCollectionStartDate];
  [coder encodeObject:self.logSourceMetrics forKey:kLogSourceMetrics];
}

@end
