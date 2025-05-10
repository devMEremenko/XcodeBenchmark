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
 * Builds a new reCAPTCHA Client for the given Site Key.
 *
 * The SDK currently supports one Site Key. Passing a different Site Key will
 * throw an exception.
 *
 * @param siteKey reCAPTCHA Site Key for the app.
 * @param completion Callback function to return the RecaptchaClient or an error.
 */
+ (void)fetchClientWithSiteKey:(nonnull NSString *)siteKey
                    completion:(void (^)(id<RCARecaptchaClientProtocol> _Nullable recaptchaClient,
                                         NSError *_Nullable error))completion
    NS_SWIFT_NAME(fetchClient(withSiteKey:completion:));
@end

NS_ASSUME_NONNULL_END