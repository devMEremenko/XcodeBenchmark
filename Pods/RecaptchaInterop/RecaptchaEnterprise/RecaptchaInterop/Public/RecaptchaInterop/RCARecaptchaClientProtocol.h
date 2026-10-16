// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <Foundation/Foundation.h>

#import "RCAActionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/** Interface to interact with reCAPTCHA. */
@protocol RCARecaptchaClientProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * Executes reCAPTCHA on a user action.
 *
 * It is suggested the usage of 10 seconds for the timeout. The minimum value
 * is 5 seconds.
 *
 * @param action The user action to protect.
 * @param timeout Timeout for execute in milliseconds.
 * @param completion Callback function to return the execute result.
 */
- (void)execute:(nonnull id<RCAActionProtocol>)action
    withTimeout:(double)timeout
     completion:(void (^)(NSString *_Nullable token, NSError *_Nullable error))completion
    NS_SWIFT_NAME(execute(withAction:withTimeout:completion:));

/**
 * Executes reCAPTCHA on a user action.
 *
 * This method will throw a timeout exception after 10 seconds.
 *
 * @param action The user action to protect.
 * @param completion Callback function to return the execute result.
 */
- (void)execute:(nonnull id<RCAActionProtocol>)action
     completion:(void (^)(NSString *_Nullable token, NSError *_Nullable error))completion
    NS_SWIFT_NAME(execute(withAction:completion:));

@end

NS_ASSUME_NONNULL_END
