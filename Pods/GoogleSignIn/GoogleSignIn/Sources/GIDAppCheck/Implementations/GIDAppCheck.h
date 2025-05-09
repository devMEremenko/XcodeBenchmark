/*
 * Copyright 2023 Google LLC
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

@protocol GACAppCheckProvider;
@class GACAppCheckToken;

extern NSString *const kGIDAppCheckPreparedKey;

NS_CLASS_AVAILABLE_IOS(14)
@interface GIDAppCheck : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates the instance of this App Check wrapper class using `GACAppCheckDebugProvider`.
///
/// @param APIKey The API Key to use when creating the debug App Check provider.
///
/// The instance is created using `+[NSUserDefaults standardUserDefaults]`.
+ (instancetype)appCheckUsingDebugProviderWithAPIKey:(NSString *)APIKey;

/// Creates the instance of this App Check wrapper class using `GACAppAttestProvider`.
///
/// The instance is created using `+[NSUserDefaults standardUserDefaults]`.
+ (instancetype)appCheckUsingAppAttestProvider;

/// Creates the instance of this App Check wrapper class.
///
/// @param appCheckProvider The instance performing the Firebase App Check token requests. If `nil`,
///     then a default implementation will be used.
/// @param userDefaults The instance of `NSUserDefaults` that `GIDAppCheck` will use to store its
///     preparation status. If nil, `GIDAppCheck` will use `-[NSUserDefaults standardUserDefaults]`.
- (instancetype)initWithAppCheckProvider:(id<GACAppCheckProvider>)appCheckProvider
                            userDefaults:(NSUserDefaults *)userDefaults NS_DESIGNATED_INITIALIZER;

/// Prewarms the library for App Check by asking Firebase App Check to generate the App Attest key
/// id and perform the initial attestation process (if needed).
///
/// @param completion A `nullable` callback with a `nullable` `NSError` if preparation fails.
- (void)prepareForAppCheckWithCompletion:(nullable void (^)(NSError * _Nullable error))completion;

/// Fetches the limited use Firebase token.
///
/// @param completion A `nullable` callback with the `FIRAppCheckToken`, or an `NSError` otherwise.
- (void)getLimitedUseTokenWithCompletion:
    (nullable void (^)(GACAppCheckToken *token, NSError * _Nullable error))completion;

/// Whether or not the App Attest key ID created and the attestation object has been fetched.
- (BOOL)isPrepared;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
