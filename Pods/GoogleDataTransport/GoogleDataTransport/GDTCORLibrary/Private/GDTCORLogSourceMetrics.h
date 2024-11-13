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

@class GDTCOREvent;

NS_ASSUME_NONNULL_BEGIN

/// A model object that tracks, per log source, the number of events dropped for a variety of
/// reasons. An event is considered "dropped" when the event is no longer persisted by the SDK.
@interface GDTCORLogSourceMetrics : NSObject <NSSecureCoding>

/// Creates an empty log source metrics instance.
+ (instancetype)metrics;

/// Creates a log source metrics for a collection of events that were dropped for a given reason.
/// @param events The collection of events that were dropped.
/// @param reason The reason for which given events were dropped.
+ (instancetype)metricsWithEvents:(NSArray<GDTCOREvent *> *)events
                 droppedForReason:(GDTCOREventDropReason)reason;

/// This API is unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Returns a log source metrics instance created by merging the receiving log
/// source metrics with the given log source metrics.
/// @param logSourceMetrics The given log source metrics to merge with.
- (GDTCORLogSourceMetrics *)logSourceMetricsByMergingWithLogSourceMetrics:
    (GDTCORLogSourceMetrics *)logSourceMetrics;

/// Returns a Boolean value that indicates whether the receiving log source metrics is equal to
/// the given log source metrics.
/// @param otherLogSourceMetrics The log source metrics with which to compare the
/// receiving log source metrics.
- (BOOL)isEqualToLogSourceMetrics:(GDTCORLogSourceMetrics *)otherLogSourceMetrics;

@end

NS_ASSUME_NONNULL_END
