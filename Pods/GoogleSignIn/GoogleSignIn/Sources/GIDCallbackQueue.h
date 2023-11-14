/*
 * Copyright 2021 Google LLC
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

NS_ASSUME_NONNULL_BEGIN

@class GIDCallbackQueue;

// The block type of callbacks in the queue.
typedef void (^GIDCallbackQueueCallback)(void);

// The class handles a queue for callbacks for asynchronous operations.
// The queue starts in a ready state. Call |wait| and |next| to mark the
// start and end of asynchronous operations.
@interface GIDCallbackQueue : NSObject

// Marks the start of an asynchronous operation. Any remaining callbacks will
// not be called until |next| is called. The queue object will be retained while
// some asynchronous operation is pending.
- (void)wait;

// Marks the end of an asynchronous operation. If no more operation remain,
// all remaining callbacks are called in the order they are added. Note that
// some earlier callbackes can start asynchronous operations themselves, thus
// blocking later callbacks until they are finished.
- (void)next;

// Resets the callback queue to the ready state and removes all callbacks.
- (void)reset;

// Adds a callback to the end of the callback queue. Callbacks added later will
// only be called when both the callbacks added eariler and the asynchronous
// operations they started if any are finished.
- (void)addCallback:(GIDCallbackQueueCallback)callback;

@end

NS_ASSUME_NONNULL_END
