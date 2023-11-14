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

#import "RCARecaptchaClientProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/** Interface to interact with reCAPTCHA and retrieve a reCAPTCHA Client. */
@protocol RCARecaptchaProtocol

- (instancetype)init NS_UNAVAILABLE;

/**
 * Builds a new reCAPTCHA Client for the given Site Key and timeout.
 *
 * The SDK currently supports one Site Key. Passing a different Site Key will
 * throw an exception.
 *
 * At least a 10000 millisecond timeout is suggested to allow for slow
 * networking, though in some cases longer timeouts may be necessary. The
 * minimum allowable value is 5000 milliseconds.
 *
 * @param siteKey reCAPTCHA Site Key for the app.
 * @param timeout Timeout for getClient in milliseconds.
 * @param completion Callback function to return the RecaptchaClient or an error.
 */
+ (void)getClientWithSiteKey:(nonnull NSString *)siteKey
                 withTimeout:(double)timeout
                  completion:(void (^)(id<RCARecaptchaClientProtocol> _Nullable recaptchaClient,
                                       NSError *_Nullable error))completion
    NS_SWIFT_NAME(getClient(withSiteKey:withTimeout:completion:));

/**
 * Builds a new reCAPTCHA Client for the given Site Key.
 *
 * The SDK currently supports one Site Key. Passing a different Site Key will
 * throw an exception.
 *
 * This method will throw a timeout exception after 10 seconds.
 *
 * @param siteKey reCAPTCHA Site Key for the app.
 * @param completion Callback function to return the RecaptchaClient or an error.
 */
+ (void)getClientWithSiteKey:(nonnull NSString *)siteKey
                  completion:(void (^)(id<RCARecaptchaClientProtocol> _Nullable recaptchaClient,
                                       NSError *_Nullable error))completion
    NS_SWIFT_NAME(getClient(withSiteKey:completion:));

@end

NS_ASSUME_NONNULL_END