/*
 * Copyright 2021 Google LLC
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

#import <Foundation/Foundation.h>

@class GTMKeychainStore;
@class GTMAuthSession;

NS_ASSUME_NONNULL_BEGIN

/// A class providing migration support for auth state saved by older versions of the SDK.
@interface GIDAuthStateMigration : NSObject

/// Creates an instance of this migration type with the keychain storage wrapper it will use.
- (instancetype)initWithKeychainStore:(GTMKeychainStore *)keychainStore NS_DESIGNATED_INITIALIZER;

/// Perform a one-time migration for auth state saved by GPPSignIn 1.x or GIDSignIn 1.0 - 4.x to the
/// GTMAppAuth storage introduced in GIDSignIn 5.0.
- (void)migrateIfNeededWithTokenURL:(NSURL *)tokenURL
                       callbackPath:(NSString *)callbackPath
                       keychainName:(NSString *)keychainName
                     isFreshInstall:(BOOL)isFreshInstall;

@end

NS_ASSUME_NONNULL_END
