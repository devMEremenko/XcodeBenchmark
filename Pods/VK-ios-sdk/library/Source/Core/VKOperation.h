//
//  VKOperation.h
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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VKOperationState) {
    /// Operation paused
    VKOperationPausedState = -1,
    /// Operation ready, and will be executed
    VKOperationReadyState = 1,
    /// Operation executing just in time
    VKOperationExecutingState = 2,
    /// Operation finished or canceled
    VKOperationFinishedState = 3,
};

/**
Basic class for operations
*/
@interface VKOperation : NSOperation
/// This operation state. Value from VKOperationState enum
@property(readwrite, nonatomic, assign) VKOperationState state;
/// Operation working lock
@property(readwrite, nonatomic, strong) NSRecursiveLock *lock;
/// Sets dispatch queue for returning result
@property(nonatomic, assign) dispatch_queue_t responseQueue;
@end
