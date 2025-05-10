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

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"

@class GDTCORMetrics;

NS_ASSUME_NONNULL_BEGIN

@interface GDTCOREvent (GDTMetricsSupport)

/// Creates and returns an event for the given target with the given metrics.
/// @param metrics The metrics to set at the event's data.
/// @param target The backend target that the event corresponds to.
+ (GDTCOREvent *)eventWithMetrics:(GDTCORMetrics *)metrics forTarget:(GDTCORTarget)target;

@end

NS_ASSUME_NONNULL_END
