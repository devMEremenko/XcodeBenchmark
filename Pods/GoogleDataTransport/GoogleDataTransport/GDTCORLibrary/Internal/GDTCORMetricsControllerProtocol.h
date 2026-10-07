/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCOREventDropReason.h"
#import "GoogleDataTransport/GDTCORLibrary/Internal/GDTCORStorageProtocol.h"

@class FBLPromise<ResultType>;
@class GDTCOREvent;
@class GDTCORMetrics;

NS_ASSUME_NONNULL_BEGIN

/// A storage delegate that can perform metrics related tasks.
@protocol GDTCORMetricsControllerProtocol <GDTCORStorageDelegate>

/// Updates the corresponding log source metricss for the given events dropped for a given
/// reason.
/// @param reason The reason why the events are being dropped.
/// @param events The events that being dropped.
- (FBLPromise<NSNull *> *)logEventsDroppedForReason:(GDTCOREventDropReason)reason
                                             events:(NSSet<GDTCOREvent *> *)events;

/// Gets and resets the currently stored metrics.
/// @return A promise resolving with the metrics retrieved before the reset.
- (FBLPromise<GDTCORMetrics *> *)getAndResetMetrics;

/// Offers metrics for re-storing in storage.
/// @note If the metrics are determined to be from the future, they will be ignored.
/// @param metrics The metrics to offer for storage.
- (FBLPromise<NSNull *> *)offerMetrics:(GDTCORMetrics *)metrics;

@end

/// Returns a metrics controller instance for the given target.
/// @param target The target to retrieve a corresponding metrics controller from.
/// @return The given target's corresponding metrics controller instance, or `nil` if it does not
/// have one.
FOUNDATION_EXPORT
id<GDTCORMetricsControllerProtocol> _Nullable GDTCORMetricsControllerInstanceForTarget(
    GDTCORTarget target);

NS_ASSUME_NONNULL_END
