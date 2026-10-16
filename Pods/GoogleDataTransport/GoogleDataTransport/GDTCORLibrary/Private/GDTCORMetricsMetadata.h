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

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"

@class GDTCORLogSourceMetrics;

NS_ASSUME_NONNULL_BEGIN

/// An encodable model object that contains metadata that is persisted in storage until ready to be
/// used to create a ``GDTCORMetrics`` instance.
@interface GDTCORMetricsMetadata : NSObject <NSSecureCoding>

/// The start of the time window over which the metrics were collected.
@property(nonatomic, copy, readonly) NSDate *collectionStartDate;

/// The log source metrics associated with the metrics.
@property(nonatomic, copy, readonly) GDTCORLogSourceMetrics *logSourceMetrics;

/// Creates a metrics metadata object with the provided information.
/// @param collectedSinceDate The start of the time window over which the metrics were collected.
/// @param logSourceMetrics The metrics object that tracks metrics for each  log source.
+ (instancetype)metadataWithCollectionStartDate:(NSDate *)collectedSinceDate
                               logSourceMetrics:(GDTCORLogSourceMetrics *)logSourceMetrics;

/// This API is unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Returns a Boolean value that indicates whether the receiving metrics metadata is equal to
/// the given metrics metadata.
/// @param otherMetricsMetadata The metrics metadata with which to compare the
/// receiving metrics metadata.
- (BOOL)isEqualToMetricsMetadata:(GDTCORMetricsMetadata *)otherMetricsMetadata;

@end

NS_ASSUME_NONNULL_END
