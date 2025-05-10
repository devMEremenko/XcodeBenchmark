/*
 * Copyright 2019 Google
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
#import "FirebaseMessaging/Sources/Token/FIRMessagingCheckinService.h"

NS_ASSUME_NONNULL_BEGIN

@class FIRMessagingCheckinPreferences;
/**
 *  @related FIRInstanceIDCheckinService
 *
 *  The completion handler invoked once the fetch from Checkin server finishes.
 *  For successful fetches we returned checkin information by the checkin service
 *  and `nil` error, else we return the appropriate error object as reported by the
 *  Checkin Service.
 *
 *  @param checkinPreferences The checkin preferences as fetched from the server.
 *  @param error              The error object which fetching GServices data.
 */
typedef void (^FIRMessagingDeviceCheckinCompletion)(
    FIRMessagingCheckinPreferences *_Nullable checkinPreferences, NSError *_Nullable error);
/**
 *  FIRMessagingAuthService is responsible for retrieving, caching, and supplying checkin info
 *  for the rest of Instance ID. A checkin can be scheduled, meaning that it will keep retrying the
 *  checkin request until it is successful. A checkin can also be requested directly, with a
 *  completion handler.
 */
@interface FIRMessagingAuthService : NSObject

#pragma mark - Checkin Service

- (BOOL)hasCheckinPlist;

/**
 *  Checks if the current deviceID and secret are valid or not.
 *
 *  @return YES if the checkin credentials are valid else NO.
 */
- (BOOL)hasValidCheckinInfo;

/**
 *  Fetch checkin info from the server. This would usually refresh the existing
 *  checkin credentials for the current app.
 *
 *  @param handler The completion handler to invoke once the checkin info has been
 *                 refreshed.
 */
- (void)fetchCheckinInfoWithHandler:(nullable FIRMessagingDeviceCheckinCompletion)handler;

/**
 *  Schedule checkin. Will hit the network only if the currently loaded checkin
 *  preferences are stale.
 *
 *  @param immediately YES if we want it to be scheduled immediately else NO.
 */
- (void)scheduleCheckin:(BOOL)immediately;

/**
 *  Returns the checkin preferences currently loaded in memory. The Checkin preferences
 *  can be either valid or invalid.
 *
 *  @return The checkin preferences loaded in memory.
 */
- (FIRMessagingCheckinPreferences *)checkinPreferences;

/**
 *  Cancels any ongoing checkin fetch, if any.
 */
- (void)stopCheckinRequest;

/**
 *  Resets the checkin information.
 *
 *  @param handler       The callback handler which is invoked when checkin reset is complete,
 *                       with an error if there is any.
 */
- (void)resetCheckinWithHandler:(void (^)(NSError *error))handler;

@end

NS_ASSUME_NONNULL_END
