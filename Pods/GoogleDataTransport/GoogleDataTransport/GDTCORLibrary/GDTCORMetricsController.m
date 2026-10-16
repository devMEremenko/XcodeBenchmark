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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsController.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORRegistrar.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageProtocol.h"

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORFlatFileStorage+Promises.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetricsMetadata.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORStorageMetadata.h"

@interface GDTCORMetricsController ()
/// The underlying storage object where metrics are stored.
@property(nonatomic) id<GDTCORStoragePromiseProtocol> storage;

@end

@implementation GDTCORMetricsController

+ (void)load {
#if GDT_TEST
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetTest];
#endif  // GDT_TEST
  // Only the Firelog backend supports metrics collection.
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetCSH];
  [[GDTCORRegistrar sharedInstance] registerMetricsController:[self sharedInstance]
                                                       target:kGDTCORTargetFLL];
}

+ (instancetype)sharedInstance {
  static id sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] initWithStorage:[GDTCORFlatFileStorage sharedInstance]];
  });
  return sharedInstance;
}

- (instancetype)initWithStorage:(id<GDTCORStoragePromiseProtocol>)storage {
  self = [super init];
  if (self) {
    _storage = storage;
  }
  return self;
}

- (nonnull FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                                     events:(nonnull NSSet<GDTCOREvent *> *)events {
  // No-op if there are no events to log.
  if ([events count] == 0) {
    return [FBLPromise resolvedWith:nil];
  }

  __auto_type handler = ^GDTCORMetricsMetadata *(GDTCORMetricsMetadata *_Nullable metricsMetadata,
                                                 NSError *_Nullable fetchError) {
    GDTCORLogSourceMetrics *logSourceMetrics =
        [GDTCORLogSourceMetrics metricsWithEvents:[events allObjects] droppedForReason:reason];

    if (metricsMetadata) {
      GDTCORLogSourceMetrics *updatedLogSourceMetrics = [metricsMetadata.logSourceMetrics
          logSourceMetricsByMergingWithLogSourceMetrics:logSourceMetrics];

      return [GDTCORMetricsMetadata
          metadataWithCollectionStartDate:[metricsMetadata collectionStartDate]
                         logSourceMetrics:updatedLogSourceMetrics];
    } else {
      // There was an error (e.g. empty storage); `metricsMetadata` is nil.
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
      return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                                   logSourceMetrics:logSourceMetrics];
    }
  };

  return [_storage fetchAndUpdateMetricsWithHandler:handler];
}

- (nonnull FBLPromise<GDTCORMetrics *> *)getAndResetMetrics {
  __block GDTCORMetricsMetadata *_Nullable snapshottedMetricsMetadata = nil;

  __auto_type handler = ^GDTCORMetricsMetadata *(GDTCORMetricsMetadata *_Nullable metricsMetadata,
                                                 NSError *_Nullable fetchError) {
    if (metricsMetadata) {
      snapshottedMetricsMetadata = metricsMetadata;
    } else {
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);
    }
    return [GDTCORMetricsMetadata metadataWithCollectionStartDate:[NSDate date]
                                                 logSourceMetrics:[GDTCORLogSourceMetrics metrics]];
  };

  return [_storage fetchAndUpdateMetricsWithHandler:handler]
      .validate(^BOOL(NSNull *__unused _) {
        // Break and reject the promise chain when storage contains no metrics
        // metadata.
        return snapshottedMetricsMetadata != nil;
      })
      .then(^FBLPromise *(NSNull *__unused _) {
        // Fetch and return storage metadata (needed for metrics).
        return [self.storage fetchStorageMetadata];
      })
      .then(^GDTCORMetrics *(GDTCORStorageMetadata *storageMetadata) {
        // Use the fetched metrics & storage metadata to create and return a
        // complete metrics object.
        return [GDTCORMetrics metricsWithMetricsMetadata:snapshottedMetricsMetadata
                                         storageMetadata:storageMetadata];
      });
}

- (nonnull FBLPromise<NSNull *> *)offerMetrics:(nonnull GDTCORMetrics *)metrics {
  // No-op if there are no metrics to offer.
  if (metrics == nil) {
    return [FBLPromise resolvedWith:nil];
  }

  __auto_type handler = ^GDTCORMetricsMetadata *(GDTCORMetricsMetadata *_Nullable metricsMetadata,
                                                 NSError *_Nullable fetchError) {
    if (metricsMetadata) {
      if (metrics.collectionStartDate.timeIntervalSince1970 <=
          metricsMetadata.collectionStartDate.timeIntervalSince1970) {
        // If the metrics to append are older than the metrics represented by
        // the currently stored metrics, then return a new metadata object that
        // incorporates the data from the given metrics.
        return [GDTCORMetricsMetadata
            metadataWithCollectionStartDate:[metrics collectionStartDate]
                           logSourceMetrics:[metricsMetadata.logSourceMetrics
                                                logSourceMetricsByMergingWithLogSourceMetrics:
                                                    metrics.logSourceMetrics]];
      } else {
        // This catches an edge case where the given metrics to append are
        // newer than metrics represented by the currently stored metrics
        // metadata. In this case, return the existing metadata object as the
        // given metrics are assumed to already be accounted for by the
        // currently stored metadata.
        return metricsMetadata;
      }
    } else {
      // There was an error (e.g. empty storage); `metricsMetadata` is nil.
      GDTCORLogDebug(@"Error fetching metrics metadata: %@", fetchError);

      NSDate *now = [NSDate date];
      if (metrics.collectionStartDate.timeIntervalSince1970 <= now.timeIntervalSince1970) {
        // The given metrics are were recorded up until now. They wouldn't
        // be offered if they were successfully uploaded so their
        // corresponding metadata can be safely placed back in storage.
        return [GDTCORMetricsMetadata metadataWithCollectionStartDate:metrics.collectionStartDate
                                                     logSourceMetrics:metrics.logSourceMetrics];
      } else {
        // This catches an edge case where the given metrics are from the
        // future. If this occurs, ignore them and store an empty metadata
        // object intended to track metrics metadata from this time forward.
        return [GDTCORMetricsMetadata
            metadataWithCollectionStartDate:[NSDate date]
                           logSourceMetrics:[GDTCORLogSourceMetrics metrics]];
      }
    }
  };

  return [_storage fetchAndUpdateMetricsWithHandler:handler];
}

#pragma mark - GDTCORStorageDelegate

- (void)storage:(id<GDTCORStorageProtocol>)storage
    didRemoveExpiredEvents:(nonnull NSSet<GDTCOREvent *> *)events {
  [self logEventsDroppedForReason:GDTCOREventDropReasonMessageTooOld events:events];
}

- (void)storage:(nonnull id<GDTCORStorageProtocol>)storage
    didDropEvent:(nonnull GDTCOREvent *)event {
  [self logEventsDroppedForReason:GDTCOREventDropReasonStorageFull
                           events:[NSSet setWithObject:event]];
}

@end
