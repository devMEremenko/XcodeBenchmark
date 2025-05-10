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

#import "AppCheckCore/Sources/DebugProvider/API/GACAppCheckDebugProviderAPIService.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "AppCheckCore/Sources/Core/APIService/GACAppCheckAPIService.h"
#import "AppCheckCore/Sources/Core/APIService/GACAppCheckToken+APIResponse.h"

#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"
#import "AppCheckCore/Sources/Core/GACAppCheckLogger+Internal.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kContentTypeKey = @"Content-Type";
static NSString *const kJSONContentType = @"application/json";
static NSString *const kDebugTokenField = @"debug_token";
static NSString *const kLimitedUseField = @"limited_use";

@interface GACAppCheckDebugProviderAPIService ()

@property(nonatomic, readonly) id<GACAppCheckAPIServiceProtocol> APIService;

@property(nonatomic, readonly) NSString *resourceName;

@end

@implementation GACAppCheckDebugProviderAPIService

- (instancetype)initWithAPIService:(id<GACAppCheckAPIServiceProtocol>)APIService
                      resourceName:(NSString *)resourceName {
  self = [super init];
  if (self) {
    _APIService = APIService;
    _resourceName = resourceName;
  }
  return self;
}

#pragma mark - Public API

- (FBLPromise<GACAppCheckToken *> *)appCheckTokenWithDebugToken:(NSString *)debugToken
                                                     limitedUse:(BOOL)limitedUse {
  NSString *URLString = [NSString
      stringWithFormat:@"%@/%@:exchangeDebugToken", self.APIService.baseURL, self.resourceName];
  NSURL *URL = [NSURL URLWithString:URLString];

  return [self HTTPBodyWithDebugToken:debugToken limitedUse:limitedUse]
      .then(^FBLPromise<GACURLSessionDataResponse *> *(NSData *HTTPBody) {
        return [self.APIService sendRequestWithURL:URL
                                        HTTPMethod:@"POST"
                                              body:HTTPBody
                                 additionalHeaders:@{kContentTypeKey : kJSONContentType}];
      })
      .then(^id _Nullable(GACURLSessionDataResponse *_Nullable response) {
        return [self.APIService appCheckTokenWithAPIResponse:response];
      });
}

#pragma mark - Helpers

- (FBLPromise<NSData *> *)HTTPBodyWithDebugToken:(NSString *)debugToken
                                      limitedUse:(BOOL)limitedUse {
  if (debugToken.length <= 0) {
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise
        reject:[GACAppCheckErrorUtil errorWithFailureReason:@"Debug token must not be empty."]];
    return rejectedPromise;
  }

  return [FBLPromise onQueue:[self backgroundQueue]
                          do:^id _Nullable {
                            NSError *encodingError;
                            NSData *payloadJSON =
                                [NSJSONSerialization dataWithJSONObject:@{
                                  kDebugTokenField : debugToken,
                                  kLimitedUseField : @(limitedUse)
                                }
                                                                options:0
                                                                  error:&encodingError];

                            if (payloadJSON != nil) {
                              return payloadJSON;
                            } else {
                              return [GACAppCheckErrorUtil JSONSerializationError:encodingError];
                            }
                          }];
}

- (dispatch_queue_t)backgroundQueue {
  return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
}

@end

NS_ASSUME_NONNULL_END
