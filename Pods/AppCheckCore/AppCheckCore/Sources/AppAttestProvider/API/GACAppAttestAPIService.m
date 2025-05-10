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

#import "AppCheckCore/Sources/AppAttestProvider/API/GACAppAttestAPIService.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "AppCheckCore/Sources/AppAttestProvider/API/GACAppAttestAttestationResponse.h"
#import "AppCheckCore/Sources/Core/APIService/GACAppCheckAPIService.h"
#import "AppCheckCore/Sources/Core/APIService/GACURLSessionDataResponse.h"
#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kRequestFieldArtifact = @"artifact";
static NSString *const kRequestFieldAssertion = @"assertion";
static NSString *const kRequestFieldAttestation = @"attestation_statement";
static NSString *const kRequestFieldChallenge = @"challenge";
static NSString *const kRequestFieldKeyID = @"key_id";
static NSString *const kRequestFieldLimitedUse = @"limited_use";

static NSString *const kExchangeAppAttestAssertionEndpoint = @"exchangeAppAttestAssertion";
static NSString *const kExchangeAppAttestAttestationEndpoint = @"exchangeAppAttestAttestation";
static NSString *const kGenerateAppAttestChallengeEndpoint = @"generateAppAttestChallenge";

static NSString *const kContentTypeKey = @"Content-Type";
static NSString *const kJSONContentType = @"application/json";
static NSString *const kHTTPMethodPost = @"POST";

@interface GACAppAttestAPIService ()

@property(nonatomic, readonly) id<GACAppCheckAPIServiceProtocol> APIService;

@property(nonatomic, readonly) NSString *resourceName;

@end

@implementation GACAppAttestAPIService

- (instancetype)initWithAPIService:(id<GACAppCheckAPIServiceProtocol>)APIService
                      resourceName:(NSString *)resourceName {
  self = [super init];
  if (self) {
    _APIService = APIService;
    _resourceName = [resourceName copy];
  }
  return self;
}

#pragma mark - Assertion request

- (FBLPromise<GACAppCheckToken *> *)getAppCheckTokenWithArtifact:(NSData *)artifact
                                                       challenge:(NSData *)challenge
                                                       assertion:(NSData *)assertion
                                                      limitedUse:(BOOL)limitedUse {
  NSURL *URL = [self URLForEndpoint:kExchangeAppAttestAssertionEndpoint];

  return [self HTTPBodyWithArtifact:artifact
                          challenge:challenge
                          assertion:assertion
                         limitedUse:limitedUse]
      .then(^FBLPromise<GACURLSessionDataResponse *> *(NSData *HTTPBody) {
        return [self.APIService sendRequestWithURL:URL
                                        HTTPMethod:kHTTPMethodPost
                                              body:HTTPBody
                                 additionalHeaders:@{kContentTypeKey : kJSONContentType}];
      })
      .then(^id _Nullable(GACURLSessionDataResponse *_Nullable response) {
        return [self.APIService appCheckTokenWithAPIResponse:response];
      });
}

#pragma mark - Random Challenge

- (nonnull FBLPromise<NSData *> *)getRandomChallenge {
  NSURL *URL = [self URLForEndpoint:kGenerateAppAttestChallengeEndpoint];

  return [FBLPromise onQueue:[self backgroundQueue]
                          do:^id _Nullable {
                            return [self.APIService sendRequestWithURL:URL
                                                            HTTPMethod:kHTTPMethodPost
                                                                  body:nil
                                                     additionalHeaders:nil];
                          }]
      .then(^id _Nullable(GACURLSessionDataResponse *_Nullable response) {
        return [self randomChallengeWithAPIResponse:response];
      });
}

#pragma mark - Challenge response parsing

- (FBLPromise<NSData *> *)randomChallengeWithAPIResponse:(GACURLSessionDataResponse *)response {
  return [FBLPromise onQueue:[self backgroundQueue]
                          do:^id _Nullable {
                            NSError *error;

                            NSData *randomChallenge =
                                [self randomChallengeFromResponseBody:response.HTTPBody
                                                                error:&error];

                            return randomChallenge ?: error;
                          }];
}

- (nullable NSData *)randomChallengeFromResponseBody:(NSData *)response error:(NSError **)outError {
  if (response.length <= 0) {
    GACAppCheckSetErrorToPointer(
        [GACAppCheckErrorUtil errorWithFailureReason:@"Empty server response body."], outError);
    return nil;
  }

  NSError *JSONError;
  NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:response
                                                               options:0
                                                                 error:&JSONError];

  if (![responseDict isKindOfClass:[NSDictionary class]]) {
    GACAppCheckSetErrorToPointer([GACAppCheckErrorUtil JSONSerializationError:JSONError], outError);
    return nil;
  }

  NSString *challenge = responseDict[@"challenge"];
  if (![challenge isKindOfClass:[NSString class]]) {
    GACAppCheckSetErrorToPointer(
        [GACAppCheckErrorUtil appCheckTokenResponseErrorWithMissingField:@"challenge"], outError);
    return nil;
  }

  NSData *randomChallenge = [[NSData alloc] initWithBase64EncodedString:challenge options:0];
  return randomChallenge;
}

#pragma mark - Attestation request

- (FBLPromise<GACAppAttestAttestationResponse *> *)attestKeyWithAttestation:(NSData *)attestation
                                                                      keyID:(NSString *)keyID
                                                                  challenge:(NSData *)challenge
                                                                 limitedUse:(BOOL)limitedUse {
  NSURL *URL = [self URLForEndpoint:kExchangeAppAttestAttestationEndpoint];

  return [self HTTPBodyWithAttestation:attestation
                                 keyID:keyID
                             challenge:challenge
                            limitedUse:limitedUse]
      .then(^FBLPromise<GACURLSessionDataResponse *> *(NSData *HTTPBody) {
        return [self.APIService sendRequestWithURL:URL
                                        HTTPMethod:kHTTPMethodPost
                                              body:HTTPBody
                                 additionalHeaders:@{kContentTypeKey : kJSONContentType}];
      })
      .thenOn(
          [self backgroundQueue], ^id _Nullable(GACURLSessionDataResponse *_Nullable URLResponse) {
            NSError *error;

            __auto_type response =
                [[GACAppAttestAttestationResponse alloc] initWithResponseData:URLResponse.HTTPBody
                                                                  requestDate:[NSDate date]
                                                                        error:&error];

            return response ?: error;
          });
}

#pragma mark - Request HTTP Body

- (FBLPromise<NSData *> *)HTTPBodyWithArtifact:(NSData *)artifact
                                     challenge:(NSData *)challenge
                                     assertion:(NSData *)assertion
                                    limitedUse:(BOOL)limitedUse {
  if (artifact.length <= 0 || challenge.length <= 0 || assertion.length <= 0) {
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise reject:[GACAppCheckErrorUtil
                                errorWithFailureReason:@"Missing or empty request parameter."]];
    return rejectedPromise;
  }

  return [FBLPromise onQueue:[self backgroundQueue]
                          do:^id {
                            id JSONObject = @{
                              kRequestFieldArtifact : [self base64StringWithData:artifact],
                              kRequestFieldChallenge : [self base64StringWithData:challenge],
                              kRequestFieldAssertion : [self base64StringWithData:assertion],
                              kRequestFieldLimitedUse : @(limitedUse)
                            };

                            return [self HTTPBodyWithJSONObject:JSONObject];
                          }];
}

- (FBLPromise<NSData *> *)HTTPBodyWithAttestation:(NSData *)attestation
                                            keyID:(NSString *)keyID
                                        challenge:(NSData *)challenge
                                       limitedUse:(BOOL)limitedUse {
  if (attestation.length <= 0 || keyID.length <= 0 || challenge.length <= 0) {
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise reject:[GACAppCheckErrorUtil
                                errorWithFailureReason:@"Missing or empty request parameter."]];
    return rejectedPromise;
  }

  return [FBLPromise onQueue:[self backgroundQueue]
                          do:^id {
                            id JSONObject = @{
                              kRequestFieldKeyID : keyID,
                              kRequestFieldAttestation : [self base64StringWithData:attestation],
                              kRequestFieldChallenge : [self base64StringWithData:challenge],
                              kRequestFieldLimitedUse : @(limitedUse)
                            };

                            return [self HTTPBodyWithJSONObject:JSONObject];
                          }];
}

- (FBLPromise<NSData *> *)HTTPBodyWithJSONObject:(nonnull id)JSONObject {
  NSError *encodingError;
  NSData *payloadJSON = [NSJSONSerialization dataWithJSONObject:JSONObject
                                                        options:0
                                                          error:&encodingError];
  FBLPromise<NSData *> *HTTPBodyPromise = [FBLPromise pendingPromise];
  if (payloadJSON) {
    [HTTPBodyPromise fulfill:payloadJSON];
  } else {
    [HTTPBodyPromise reject:[GACAppCheckErrorUtil JSONSerializationError:encodingError]];
  }
  return HTTPBodyPromise;
}

#pragma mark - Helpers

- (NSString *)base64StringWithData:(NSData *)data {
  return [data base64EncodedStringWithOptions:0];
}

- (NSURL *)URLForEndpoint:(NSString *)endpoint {
  NSString *URL = [[self class] URLWithBaseURL:self.APIService.baseURL
                                  resourceName:self.resourceName];
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@", URL, endpoint]];
}

+ (NSString *)URLWithBaseURL:(NSString *)baseURL resourceName:(NSString *)resourceName {
  return [NSString stringWithFormat:@"%@/%@", baseURL, resourceName];
}

- (dispatch_queue_t)backgroundQueue {
  return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
}

@end

NS_ASSUME_NONNULL_END
