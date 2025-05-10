/*
 * Copyright 2020 Google LLC
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

@class FBLPromise<Result>;
@class GACAppCheckToken;
@protocol GACAppCheckAPIServiceProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol GACAppCheckDebugProviderAPIServiceProtocol <NSObject>

- (FBLPromise<GACAppCheckToken *> *)appCheckTokenWithDebugToken:(NSString *)debugToken
                                                     limitedUse:(BOOL)limitedUse;

@end

@interface GACAppCheckDebugProviderAPIService
    : NSObject <GACAppCheckDebugProviderAPIServiceProtocol>

/// Default initializer.
/// @param APIService An instance implementing `GACAppCheckAPIServiceProtocol` to be used to send
/// network requests to the App Check backend.
/// @param resourceName The name of the resource protected by App Check; for a Firebase App this is
/// "projects/{project_id}/apps/{app_id}". See https://google.aip.dev/122 for more details about
/// resource names.
- (instancetype)initWithAPIService:(id<GACAppCheckAPIServiceProtocol>)APIService
                      resourceName:(NSString *)resourceName;

@end

NS_ASSUME_NONNULL_END
