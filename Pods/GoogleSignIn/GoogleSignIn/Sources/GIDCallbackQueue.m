// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/GIDCallbackQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface GIDCallbackQueue () {
  // Whether we are in the middle of firing callbacks loop.
  BOOL _firing;

  // Number of currently pending operations.
  int _pending;  // number of pending operations

  // The ordered list of callback blocks.
  NSMutableArray *_queue;

  // A strong reference back to self to prevent it from being released when
  // there is operation pending.
  GIDCallbackQueue *_strongSelf;
}

@end

@implementation GIDCallbackQueue

- (id)init {
  self = [super init];
  if (self) {
    _queue = [NSMutableArray new];
  }
  return self;
}

- (void)wait {
  _pending++;
  // The queue itself should be retained as long as there are pending
  // operations.
  _strongSelf = self;
}

- (void)next {
  if (!_pending) {
    return;
  }
  _pending--;
  if (!_pending) {
    // Use an autoreleasing variable to hold self temporarily so it is not
    // released while this method is executing.
    __autoreleasing GIDCallbackQueue *autoreleasingSelf = self;
    _strongSelf = nil;
    [autoreleasingSelf fire];
  }
}

- (void)reset {
  [_queue removeAllObjects];
  _pending = 0;
  _strongSelf = nil;
}

- (void)addCallback:(GIDCallbackQueueCallback)callback {
  if (!callback) {
    return;
  }
  [_queue addObject:[callback copy]];
  if (!_pending) {
    [self fire];
  }
}

// Fires the callbacks.
- (void)fire {
  if (_firing) {
    return;
  }
  _firing = YES;
  while (!_pending && [_queue count]) {
    GIDCallbackQueueCallback callback = [_queue objectAtIndex:0];
    [_queue removeObjectAtIndex:0];
    callback();
  }
  _firing = NO;
}

@end

NS_ASSUME_NONNULL_END
