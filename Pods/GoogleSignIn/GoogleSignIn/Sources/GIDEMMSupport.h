/*
 * Copyright 2022 Google LLC
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

#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// A class to support EMM (Enterprise Mobility Management).
@interface GIDEMMSupport : NSObject

// Handles potential EMM error from token fetch response.
+ (void)handleTokenFetchEMMError:(nullable NSError *)error
                      completion:(void (^)(NSError *_Nullable))completion;

// Gets a new set of URL parameters that contains updated EMM-related URL parameters if needed.
+ (NSDictionary *)updatedEMMParametersWithParameters:(NSDictionary *)parameters;

// Gets a new set of URL parameters that also contains EMM-related URL parameters if needed.
+ (NSDictionary *)parametersWithParameters:(NSDictionary *)parameters
                                emmSupport:(nullable NSString *)emmSupport
                    isPasscodeInfoRequired:(BOOL)isPasscodeInfoRequired;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
