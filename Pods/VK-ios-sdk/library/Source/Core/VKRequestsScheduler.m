//
//  VKRequestsScheduler.m
//
//  Copyright (c) 2015 VK.com
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


#import "VKRequestsScheduler.h"
#import "VKRequest.h"
#import "VKSdk.h"

@implementation VKRequestsScheduler {
    dispatch_queue_t _schedulerQueue;
    NSInteger _currentLimitPerSecond;
    NSMutableDictionary *_scheduleDict;
    BOOL _enabled;
}
//+ (NSDictionary *)limits {
//    static NSDictionary *limitsDictionary;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        limitsDictionary = @{@5000 : @3, @10000 : @5, @100000 : @8, @1000000 : @20, @(INT_MAX) : @35};
//    });
//    return limitsDictionary;
//}

+ (instancetype)instance {
    static id sInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[self alloc] init];
    });

    return sInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _currentLimitPerSecond = 3;
        _schedulerQueue = dispatch_queue_create("com.vk.requests-scheduler", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
//    if ([VKSdk instance].currentAppId) {
//        [[VKRequest requestWithMethod:@"apps.get" parameters:@{@"app_id" : [VKSdk instance].currentAppId} andHttpMethod:@"GET"] executeWithResultBlock:^(VKResponse *response) {
//            NSInteger members = [response.json[@"members_count"] integerValue];
//            NSDictionary *limitsDict = [[self class] limits];
//            NSArray *limits = [[limitsDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//                return [obj1 compare:obj2];
//            }];
//
//            for (NSNumber *curLimit in limits) {
//                if (members < curLimit.integerValue) {
//                    _currentLimitPerSecond = [limitsDict[curLimit] integerValue];
//                    break;
//                }
//            }
//
//        } errorBlock:nil];
//    }
}

- (NSTimeInterval)currentAvailableInterval {
    return 1.f / _currentLimitPerSecond;
}

- (void)scheduleRequest:(VKRequest *)req {
    if (!_enabled) {
        [req start];
        return;
    }
    dispatch_async(_schedulerQueue, ^{
        NSTimeInterval now = [[NSDate new] timeIntervalSince1970];
        NSInteger thisSecond = (NSInteger) now;
        if (!self->_scheduleDict) {
            self->_scheduleDict = [NSMutableDictionary new];
        }
        NSArray *keysToRemove = [[self->_scheduleDict allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF < %d", thisSecond]];
        [self->_scheduleDict removeObjectsForKeys:keysToRemove];
        NSInteger countForSecond = [self->_scheduleDict[@(thisSecond)] integerValue];
        if (countForSecond < self->_currentLimitPerSecond) {
            self->_scheduleDict[@(thisSecond)] = @(++countForSecond);
            [req start];
        } else {
            CGFloat delay = [self currentAvailableInterval], step = delay;
            while ([self->_scheduleDict[@(thisSecond)] integerValue] >= self->_currentLimitPerSecond) {
                delay += step;
                thisSecond = (NSInteger) (now + delay);
            }
            NSInteger nextSecCount = [self->_scheduleDict[@(thisSecond)] integerValue];
            delay += step * nextSecCount;
            self->_scheduleDict[@(thisSecond)] = @(++nextSecCount);
            dispatch_sync(dispatch_get_main_queue(), ^{
                [req performSelector:@selector(start) withObject:nil afterDelay:delay inModes:@[NSRunLoopCommonModes]];
            });
        }
    });
}
@end
