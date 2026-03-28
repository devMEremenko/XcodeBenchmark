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

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCOREvent+GDTMetricsSupport.h"

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCORMetrics+GDTCCTSupport.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORMetrics.h"

/// The mapping ID that represents the `LogSource` for GDT metrics.
static NSString *const kMetricEventMappingID = @"1710";

@implementation GDTCOREvent (GDTMetricsSupport)

+ (GDTCOREvent *)eventWithMetrics:(GDTCORMetrics *)metrics forTarget:(GDTCORTarget)target {
  GDTCOREvent *metricsEvent = [[GDTCOREvent alloc] initWithMappingID:kMetricEventMappingID
                                                              target:target];
  metricsEvent.dataObject = metrics;

  return metricsEvent;
}

@end

/// Stub used to force the linker to include the categories in this file.
void GDTCCTInclude_GDTCOREvent_GDTMetricsSupport_Category(void) {
}
