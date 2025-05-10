/*
 * Copyright 2017 Google
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

@class FIRMessagingRmqManager;

/**
 *  Handle sync messages being received via APNS.
 */
@interface FIRMessagingSyncMessageManager : NSObject

/**
 *  Initialize sync message manager.
 *
 *  @param rmqManager The RMQ manager on the client.
 *
 *  @return Sync message manager.
 */
- (instancetype)initWithRmqManager:(FIRMessagingRmqManager *)rmqManager;

/**
 *  Remove expired sync message from persistent store. Also removes messages that have
 *  been received  via APNS.
 */
- (void)removeExpiredSyncMessages;

/**
 *  App did receive a sync message via APNS.
 *
 *  @param message The sync message received.
 *
 *  @return YES if the message is a duplicate of an already received sync message else NO.
 */
- (BOOL)didReceiveAPNSSyncMessage:(NSDictionary *)message;

@end
