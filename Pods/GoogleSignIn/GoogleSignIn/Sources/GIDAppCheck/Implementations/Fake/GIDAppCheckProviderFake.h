// Copyright 2023 Google LLC
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

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <AppCheckCore/GACAppCheckProvider.h>

@class GACAppCheckToken;

NS_ASSUME_NONNULL_BEGIN

extern NSUInteger const kGIDAppCheckProviderFakeError;

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheckProviderFake : NSObject <GACAppCheckProvider>

/// Creates an instance conforming to `GACAppCheckProvider` with the provided app check token and
/// error.
///
/// @param token The `GACAppCheckToken` instance to pass into the completion called from
///     `getTokenWithCompletion:`. Use `nil` if you would like a placeholder token from
///     AppCheckCore.
/// @param error The `NSError` to pass into the completion called from
///     `getTokenWithCompletion:`.
- (instancetype)initWithAppCheckToken:(nullable GACAppCheckToken *)token
                                error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
