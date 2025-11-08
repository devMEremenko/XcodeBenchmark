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

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORLogSourceMetrics.h"

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"

static NSString *const kDroppedEventCounterByLogSource = @"droppedEventCounterByLogSource";

typedef NSDictionary<NSNumber *, NSNumber *> GDTCORDroppedEventCounter;

@interface GDTCORLogSourceMetrics ()

/// A dictionary of log sources that map to counters that reflect the number of events dropped for a
/// given set of reasons (``GDTCOREventDropReason``).
@property(nonatomic, readonly)
    NSDictionary<NSString *, GDTCORDroppedEventCounter *> *droppedEventCounterByLogSource;

@end

@implementation GDTCORLogSourceMetrics

+ (instancetype)metrics {
  return [[self alloc] initWithDroppedEventCounterByLogSource:@{}];
}

+ (instancetype)metricsWithEvents:(NSArray<GDTCOREvent *> *)events
                 droppedForReason:(GDTCOREventDropReason)reason {
  NSMutableDictionary<NSString *, GDTCORDroppedEventCounter *> *eventCounterByLogSource =
      [NSMutableDictionary dictionary];

  for (GDTCOREvent *event in [events copy]) {
    // Dropped events with a `nil` or empty mapping ID (log source) are not recorded.
    if (event.mappingID.length == 0) {
      continue;
    }

    // Get the dropped event counter for the event's mapping ID (log source).
    // If the dropped event counter for this event's mapping ID is `nil`,
    // an empty mutable counter is returned.
    NSMutableDictionary<NSNumber *, NSNumber *> *eventCounter = [NSMutableDictionary
        dictionaryWithDictionary:eventCounterByLogSource[event.mappingID] ?: @{}];

    // Increment the log source metrics for the given reason.
    NSInteger currentEventCountForReason = [eventCounter[@(reason)] integerValue];
    NSInteger updatedEventCountForReason = currentEventCountForReason + 1;

    eventCounter[@(reason)] = @(updatedEventCountForReason);

    // Update the mapping ID's (log source's) event counter with an immutable
    // copy of the updated counter.
    eventCounterByLogSource[event.mappingID] = [eventCounter copy];
  }

  return [[self alloc] initWithDroppedEventCounterByLogSource:[eventCounterByLogSource copy]];
}

- (instancetype)initWithDroppedEventCounterByLogSource:
    (NSDictionary<NSString *, GDTCORDroppedEventCounter *> *)droppedEventCounterByLogSource {
  self = [super init];
  if (self) {
    _droppedEventCounterByLogSource = [droppedEventCounterByLogSource copy];
  }
  return self;
}

- (GDTCORLogSourceMetrics *)logSourceMetricsByMergingWithLogSourceMetrics:
    (GDTCORLogSourceMetrics *)metrics {
  // Create new log source metrics by merging the current metrics with the given metrics.
  NSDictionary<NSString *, GDTCORDroppedEventCounter *> *mergedEventCounterByLogSource = [[self
      class] dictionaryByMergingDictionary:self.droppedEventCounterByLogSource
                       withOtherDictionary:metrics.droppedEventCounterByLogSource
                     uniquingKeysWithBlock:^NSDictionary *(NSDictionary *eventCounter1,
                                                           NSDictionary *eventCounter2) {
                       return [[self class]
                           dictionaryByMergingDictionary:eventCounter1
                                     withOtherDictionary:eventCounter2
                                   uniquingKeysWithBlock:^NSNumber *(NSNumber *eventCount1,
                                                                     NSNumber *eventCount2) {
                                     return @(eventCount1.integerValue + eventCount2.integerValue);
                                   }];
                     }];

  return
      [[[self class] alloc] initWithDroppedEventCounterByLogSource:mergedEventCounterByLogSource];
}

/// Creates a new dictionary by merging together two given dictionaries.
/// @param dictionary A dictionary for merging.
/// @param otherDictionary Another dictionary for merging.
/// @param block A block that is called with the values for any duplicate keys that are encountered.
/// The block returns the desired value for the merged dictionary.
+ (NSDictionary *)dictionaryByMergingDictionary:(NSDictionary *)dictionary
                            withOtherDictionary:(NSDictionary *)otherDictionary
                          uniquingKeysWithBlock:(id (^)(id value1, id value2))block {
  NSMutableDictionary *mergedDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];

  [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if (mergedDictionary[key] != nil) {
      // The key exists in both given dictionaries so combine the corresponding values with the
      // given block.
      id newValue = block(mergedDictionary[key], obj);
      mergedDictionary[key] = newValue;
    } else {
      mergedDictionary[key] = obj;
    }
  }];

  return [mergedDictionary copy];
}

#pragma mark - Equality

- (BOOL)isEqualToLogSourceMetrics:(GDTCORLogSourceMetrics *)otherMetrics {
  return [_droppedEventCounterByLogSource
      isEqualToDictionary:otherMetrics.droppedEventCounterByLogSource];
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

  return [self isEqualToLogSourceMetrics:(GDTCORLogSourceMetrics *)object];
}

- (NSUInteger)hash {
  return [_droppedEventCounterByLogSource hash];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  NSDictionary<NSString *, GDTCORDroppedEventCounter *> *droppedEventCounterByLogSource =
      [coder decodeObjectOfClasses:
                 [NSSet setWithArray:@[ NSDictionary.class, NSString.class, NSNumber.class ]]
                            forKey:kDroppedEventCounterByLogSource];

  if (!droppedEventCounterByLogSource ||
      ![droppedEventCounterByLogSource isKindOfClass:[NSDictionary class]]) {
    // If any of the fields are corrupted, the initializer should fail.
    return nil;
  }

  return [self initWithDroppedEventCounterByLogSource:droppedEventCounterByLogSource];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.droppedEventCounterByLogSource forKey:kDroppedEventCounterByLogSource];
}

#pragma mark - Description

- (NSString *)description {
  return [NSString
      stringWithFormat:@"%@ %@", [super description], self.droppedEventCounterByLogSource];
}

@end
