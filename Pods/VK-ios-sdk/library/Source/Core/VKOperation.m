//
//  VKOperation.m
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "VKOperation.h"

static inline NSString *VKKeyPathFromOperationState(VKOperationState state) {
    switch (state) {
        case VKOperationReadyState:
            return @"isReady";

        case VKOperationExecutingState:
            return @"isExecuting";

        case VKOperationFinishedState:
            return @"isFinished";

        case VKOperationPausedState:
            return @"isPaused";

        default:
            return @"state";
    }
}

static inline BOOL VKStateTransitionIsValid(VKOperationState fromState, VKOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case VKOperationReadyState:
            switch (toState) {
                case VKOperationPausedState:
                case VKOperationExecutingState:
                    return YES;

                case VKOperationFinishedState:
                    return isCancelled;

                default:
                    return NO;
            }

        case VKOperationExecutingState:
            switch (toState) {
                case VKOperationPausedState:
                case VKOperationFinishedState:
                    return YES;

                default:
                    return NO;
            }

        case VKOperationFinishedState:
            return NO;

        case VKOperationPausedState:
            return toState == VKOperationReadyState;

        default:
            return YES;
    }
}

@interface VKOperation ()

@property(readwrite, nonatomic, assign, getter = isCancelled) BOOL wasCancelled;
@end

@implementation VKOperation
- (id)init {
    self = [super init];
    self.state = VKOperationReadyState;
    return self;
}

- (void)setState:(VKOperationState)state {
    if (!VKStateTransitionIsValid(self.state, state, [self isCancelled])) {
        return;
    }

    [self.lock lock];
    NSString *oldStateKey = VKKeyPathFromOperationState(self.state);
    NSString *newStateKey = VKKeyPathFromOperationState(state);

    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (BOOL)isReady {
    return self.state == VKOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == VKOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == VKOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)cancel {
    [self willChangeValueForKey:@"isCancelled"];
    _wasCancelled = YES;
    [super cancel];
    [self didChangeValueForKey:@"isCancelled"];
}

- (void)setCompletionBlock:(void (^)(void))block {
    [self.lock lock];
    if (!block) {
        [super setCompletionBlock:nil];
    }
    else {
        __weak __typeof(&*self) weakSelf = self;

        [super setCompletionBlock:^{
            __strong __typeof(&*weakSelf) strongSelf = weakSelf;

            block();
            [strongSelf setCompletionBlock:nil];
        }];
    }
    [self.lock unlock];
}
@end
