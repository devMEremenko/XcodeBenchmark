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

#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppAttestProvider.h"

#import "AppCheckCore/Sources/AppAttestProvider/DCAppAttestService+GACAppAttestService.h"

#if __has_include(<FBLPromises/FBLPromises.h>)
#import <FBLPromises/FBLPromises.h>
#else
#import "FBLPromises.h"
#endif

#import "AppCheckCore/Sources/AppAttestProvider/API/GACAppAttestAPIService.h"
#import "AppCheckCore/Sources/AppAttestProvider/API/GACAppAttestAttestationResponse.h"
#import "AppCheckCore/Sources/AppAttestProvider/GACAppAttestProviderState.h"
#import "AppCheckCore/Sources/AppAttestProvider/GACAppAttestService.h"
#import "AppCheckCore/Sources/AppAttestProvider/Storage/GACAppAttestArtifactStorage.h"
#import "AppCheckCore/Sources/AppAttestProvider/Storage/GACAppAttestKeyIDStorage.h"
#import "AppCheckCore/Sources/Core/APIService/GACAppCheckAPIService.h"
#import "AppCheckCore/Sources/Core/Backoff/GACAppCheckBackoffWrapper.h"
#import "AppCheckCore/Sources/Core/GACAppCheckLogger+Internal.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckToken.h"

#import "AppCheckCore/Sources/Core/Utils/GACAppCheckCryptoUtils.h"

#import "AppCheckCore/Sources/AppAttestProvider/Errors/GACAppAttestRejectionError.h"
#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"
#import "AppCheckCore/Sources/Core/Errors/GACAppCheckHTTPError.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckErrors.h"

NS_ASSUME_NONNULL_BEGIN

/// A data object that contains all key attest data required for FAC token exchange.
@interface GACAppAttestKeyAttestationResult : NSObject

@property(nonatomic, readonly) NSString *keyID;
@property(nonatomic, readonly) NSData *challenge;
@property(nonatomic, readonly) NSData *attestation;

- (instancetype)initWithKeyID:(NSString *)keyID
                    challenge:(NSData *)challenge
                  attestation:(NSData *)attestation;

@end

@implementation GACAppAttestKeyAttestationResult

- (instancetype)initWithKeyID:(NSString *)keyID
                    challenge:(NSData *)challenge
                  attestation:(NSData *)attestation {
  self = [super init];
  if (self) {
    _keyID = keyID;
    _challenge = challenge;
    _attestation = attestation;
  }
  return self;
}

@end

/// A data object that contains information required for assertion request.
@interface GACAppAttestAssertionData : NSObject

@property(nonatomic, readonly) NSData *challenge;
@property(nonatomic, readonly) NSData *artifact;
@property(nonatomic, readonly) NSData *assertion;

- (instancetype)initWithChallenge:(NSData *)challenge
                         artifact:(NSData *)artifact
                        assertion:(NSData *)assertion;

@end

@implementation GACAppAttestAssertionData

- (instancetype)initWithChallenge:(NSData *)challenge
                         artifact:(NSData *)artifact
                        assertion:(NSData *)assertion {
  self = [super init];
  if (self) {
    _challenge = challenge;
    _artifact = artifact;
    _assertion = assertion;
  }
  return self;
}

@end

@interface GACAppAttestProvider ()

@property(nonatomic, readonly) id<GACAppAttestAPIServiceProtocol> APIService;
@property(nonatomic, readonly) id<GACAppAttestService> appAttestService;
@property(nonatomic, readonly) id<GACAppAttestKeyIDStorageProtocol> keyIDStorage;
@property(nonatomic, readonly) id<GACAppAttestArtifactStorageProtocol> artifactStorage;
@property(nonatomic, readonly) id<GACAppCheckBackoffWrapperProtocol> backoffWrapper;

@property(nonatomic, nullable) FBLPromise<GACAppCheckToken *> *ongoingGetTokenOperation;
@property(nonatomic, assign) BOOL ongoingGetTokenOperationLimitedUse;

@property(nonatomic, readonly) dispatch_queue_t queue;

@end

@implementation GACAppAttestProvider

- (instancetype)initWithAppAttestService:(id<GACAppAttestService>)appAttestService
                              APIService:(id<GACAppAttestAPIServiceProtocol>)APIService
                            keyIDStorage:(id<GACAppAttestKeyIDStorageProtocol>)keyIDStorage
                         artifactStorage:(id<GACAppAttestArtifactStorageProtocol>)artifactStorage
                          backoffWrapper:(id<GACAppCheckBackoffWrapperProtocol>)backoffWrapper {
  self = [super init];
  if (self) {
    _appAttestService = appAttestService;
    _APIService = APIService;
    _keyIDStorage = keyIDStorage;
    _artifactStorage = artifactStorage;
    _backoffWrapper = backoffWrapper;
    _queue = dispatch_queue_create("com.google.GACAppAttestProvider", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (instancetype)initWithServiceName:(NSString *)serviceName
                       resourceName:(NSString *)resourceName
                            baseURL:(nullable NSString *)baseURL
                             APIKey:(nullable NSString *)APIKey
                keychainAccessGroup:(nullable NSString *)accessGroup
                       requestHooks:(nullable NSArray<GACAppCheckAPIRequestHook> *)requestHooks {
  NSURLSession *URLSession = [NSURLSession
      sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];

  NSString *storageKeySuffix = [GACAppAttestProvider storageKeySuffixWithServiceName:serviceName
                                                                        resourceName:resourceName];

  GACAppAttestKeyIDStorage *keyIDStorage =
      [[GACAppAttestKeyIDStorage alloc] initWithKeySuffix:storageKeySuffix];

  GACAppCheckAPIService *APIService =
      [[GACAppCheckAPIService alloc] initWithURLSession:URLSession
                                                baseURL:baseURL
                                                 APIKey:APIKey
                                           requestHooks:requestHooks];

  GACAppAttestAPIService *appAttestAPIService =
      [[GACAppAttestAPIService alloc] initWithAPIService:APIService resourceName:resourceName];

  GACAppAttestArtifactStorage *artifactStorage =
      [[GACAppAttestArtifactStorage alloc] initWithKeySuffix:storageKeySuffix
                                                 accessGroup:accessGroup];

  GACAppCheckBackoffWrapper *backoffWrapper = [[GACAppCheckBackoffWrapper alloc] init];

  return [self initWithAppAttestService:DCAppAttestService.sharedService
                             APIService:appAttestAPIService
                           keyIDStorage:keyIDStorage
                        artifactStorage:artifactStorage
                         backoffWrapper:backoffWrapper];
}

#pragma mark - GACAppCheckProvider

- (void)getTokenWithCompletion:(void (^)(GACAppCheckToken *_Nullable, NSError *_Nullable))handler {
  [self getTokenWithLimitedUse:NO completion:handler];
}

- (void)getLimitedUseTokenWithCompletion:(void (^)(GACAppCheckToken *_Nullable,
                                                   NSError *_Nullable))handler {
  [self getTokenWithLimitedUse:YES completion:handler];
}

#pragma mark - Internal

- (void)getTokenWithLimitedUse:(BOOL)limitedUse
                    completion:(void (^)(GACAppCheckToken *_Nullable, NSError *_Nullable))handler {
  [self getTokenWithLimitedUse:limitedUse]
      // Call the handler with the result.
      .then(^FBLPromise *(GACAppCheckToken *token) {
        handler(token, nil);
        return nil;
      })
      .catch(^(NSError *error) {
        handler(nil, error);
      });
}

- (FBLPromise<GACAppCheckToken *> *)getTokenWithLimitedUse:(BOOL)limitedUse {
  return [FBLPromise
      onQueue:self.queue
           do:^id _Nullable {
             // If a get token operation is already in progress.
             if (self.ongoingGetTokenOperation) {
               // If a limited-use token is requested, or if the existing get token operation is for
               // a limited-use token and a standard token is requested, wait until after the
               // ongoing handshake has completed to kick off a new handshake; this is done to avoid
               // race conditions and to avoid returning the same limited-use token multiple times.
               if (limitedUse || self.ongoingGetTokenOperationLimitedUse != limitedUse) {
                 return self.ongoingGetTokenOperation.thenOn(
                     self.queue, ^id _Nullable(GACAppCheckToken *_Nullable value) {
                       return [self getTokenWithLimitedUse:limitedUse];
                     });
               }

               // Re-use the existing
               return self.ongoingGetTokenOperation;
             }

             // Else if there are no get token operations in progress.
             self.ongoingGetTokenOperationLimitedUse = limitedUse;
             self.ongoingGetTokenOperation =
                 [self createGetTokenSequenceWithBackoffPromiseWithLimitedUse:limitedUse]
                     // Release the ongoing operation promise on completion.
                     .thenOn(self.queue,
                             ^GACAppCheckToken *(GACAppCheckToken *token) {
                               self.ongoingGetTokenOperation = nil;
                               return token;
                             })
                     .recoverOn(self.queue, ^NSError *(NSError *error) {
                       self.ongoingGetTokenOperation = nil;
                       return error;
                     });

             return self.ongoingGetTokenOperation;
           }];
}

- (FBLPromise<GACAppCheckToken *> *)createGetTokenSequenceWithBackoffPromiseWithLimitedUse:
    (BOOL)limitedUse {
  return [self.backoffWrapper
      applyBackoffToOperation:^FBLPromise *_Nonnull {
        return [self createGetTokenSequencePromiseWithLimitedUse:limitedUse];
      }
                 errorHandler:[self.backoffWrapper defaultAppCheckProviderErrorHandler]];
}

- (FBLPromise<GACAppCheckToken *> *)createGetTokenSequencePromiseWithLimitedUse:(BOOL)limitedUse {
  // Check attestation state to decide on the next steps.
  return [FBLPromise onQueue:self.queue
             attempts:1
             delay:0
             condition:^BOOL(NSInteger attempts, NSError *_Nonnull error) {
               return [error isKindOfClass:[GACAppAttestRejectionError class]];
             }
             retry:^id {
               return [self attestationState].thenOn(
                   self.queue, ^id(GACAppAttestProviderState *attestState) {
                     switch (attestState.state) {
                       case GACAppAttestAttestationStateUnsupported:
                         GACAppCheckLogDebug(GACLoggerAppCheckMessageCodeAppAttestNotSupported,
                                             @"App Attest is not supported.");
                         return attestState.appAttestUnsupportedError;
                         break;

                       case GACAppAttestAttestationStateSupportedInitial:
                       case GACAppAttestAttestationStateKeyGenerated:
                         // Initial handshake is required for both the "initial" and the "key
                         // generated" states.
                         return [self initialHandshakeWithKeyID:attestState.appAttestKeyID
                                                     limitedUse:limitedUse];
                         break;

                       case GACAppAttestAttestationStateKeyRegistered:
                         // Refresh FAC token using the existing registered App Attest key pair.
                         return [self refreshTokenWithKeyID:attestState.appAttestKeyID
                                                   artifact:attestState.attestationArtifact
                                                 limitedUse:limitedUse];
                         break;
                     }
                   });
             }]
      .recoverOn(self.queue, ^id(NSError *error) {
        if ([error isKindOfClass:[GACAppAttestRejectionError class]]) {
          // The error was wrapped to indicate that it should be retried. The
          // retry failed so throw the wrapped error.
          return [(GACAppAttestRejectionError *)error underlyingError];
        } else {
          // Otherwise just re-throw the error.
          return error;
        }
      });
  ;
}

#pragma mark - Initial handshake sequence (attestation)

- (FBLPromise<GACAppCheckToken *> *)initialHandshakeWithKeyID:(nullable NSString *)keyID
                                                   limitedUse:(BOOL)limitedUse {
  // Attest the device. Attestation rejection errors will be bubbled up to this
  // method's caller and retried.
  return [self attestKeyGenerateIfNeededWithID:keyID limitedUse:limitedUse].thenOn(
      self.queue,
      ^FBLPromise<GACAppCheckToken *> *(NSArray * /*[keyID, attestArtifact]*/ attestationResults) {
        // Save the artifact and return the received FAC token.

        GACAppAttestKeyAttestationResult *attestation = attestationResults.firstObject;
        GACAppAttestAttestationResponse *firebaseAttestationResponse =
            attestationResults.lastObject;

        return [self saveArtifactAndGetAppCheckTokenFromResponse:firebaseAttestationResponse
                                                           keyID:attestation.keyID];
      });
}

- (FBLPromise<GACAppCheckToken *> *)saveArtifactAndGetAppCheckTokenFromResponse:
                                        (GACAppAttestAttestationResponse *)response
                                                                          keyID:(NSString *)keyID {
  return [self.artifactStorage setArtifact:response.artifact forKey:keyID].thenOn(
      self.queue, ^GACAppCheckToken *(id result) {
        return response.token;
      });
}

- (FBLPromise<GACAppAttestKeyAttestationResult *> *)attestKey:(NSString *)keyID
                                                    challenge:(NSData *)challenge {
  return [FBLPromise onQueue:self.queue
                          do:^NSData *_Nullable {
                            return [GACAppCheckCryptoUtils sha256HashFromData:challenge];
                          }]
      .thenOn(self.queue,
              ^FBLPromise<NSData *> *(NSData *challengeHash) {
                return [FBLPromise onQueue:self.queue
                           wrapObjectOrErrorCompletion:^(
                               FBLPromiseObjectOrErrorCompletion _Nonnull handler) {
                             [self.appAttestService attestKey:keyID
                                               clientDataHash:challengeHash
                                            completionHandler:handler];
                           }]
                    .recoverOn(self.queue, ^id(NSError *error) {
                      return [GACAppCheckErrorUtil appAttestAttestKeyFailedWithError:error
                                                                               keyId:keyID
                                                                      clientDataHash:challengeHash];
                    });
              })
      .thenOn(self.queue, ^FBLPromise<GACAppAttestKeyAttestationResult *> *(NSData *attestation) {
        GACAppAttestKeyAttestationResult *result =
            [[GACAppAttestKeyAttestationResult alloc] initWithKeyID:keyID
                                                          challenge:challenge
                                                        attestation:attestation];
        return [FBLPromise resolvedWith:result];
      });
}

- (FBLPromise<NSArray * /*[keyID, attestArtifact]*/> *)
    attestKeyGenerateIfNeededWithID:(nullable NSString *)keyID
                         limitedUse:(BOOL)limitedUse {
  // 1. Request a random challenge and get App Attest key ID concurrently.
  return [FBLPromise onQueue:self.queue
                         all:@[
                           // 1.1. Request random challenge.
                           [self.APIService getRandomChallenge],
                           // 1.2. Get App Attest key ID.
                           [self generateAppAttestKeyIDIfNeeded:keyID]
                         ]]
      .thenOn(self.queue,
              ^FBLPromise<GACAppAttestKeyAttestationResult *> *(NSArray *challengeAndKeyID) {
                // 2. Attest the key.
                NSData *challenge = challengeAndKeyID.firstObject;
                NSString *keyID = challengeAndKeyID.lastObject;

                return [self attestKey:keyID challenge:challenge];
              })
      .recoverOn(self.queue,
                 ^id(NSError *error) {
                   // If Apple rejected the key (DCErrorInvalidKey or
                   // DCErrorInvalidInput) then reset the attestation and
                   // throw a specific error to signal retry (GACAppAttestRejectionError).
                   NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
                   if (underlyingError && [underlyingError.domain isEqualToString:DCErrorDomain] &&
                       (underlyingError.code == DCErrorInvalidKey ||
                        underlyingError.code == DCErrorInvalidInput)) {
                     NSString *logMessage = [NSString
                         stringWithFormat:@"App Attest invalid key/input; the existing attestation "
                                          @"will be reset. DC Error Code: %@.",
                                          @(underlyingError.code)];
                     GACAppCheckLog(GACLoggerAppCheckMessageCodeAttestationRejected,
                                    GACAppCheckLogLevelDebug, logMessage);
                     // Reset the attestation.
                     return [self resetAttestation].thenOn(self.queue, ^NSError *(id result) {
                       // Throw the rejection error.
                       return [[GACAppAttestRejectionError alloc] initWithUnderlyingError:error];
                     });
                   }

                   // Otherwise just re-throw the error.
                   return error;
                 })
      .thenOn(self.queue,
              ^FBLPromise<NSArray *> *(GACAppAttestKeyAttestationResult *result) {
                // 3. Exchange the attestation to FAC token and pass the results to the next step.
                NSArray *attestationResults = @[
                  // 3.1. Just pass the attestation result to the next step.
                  [FBLPromise resolvedWith:result],
                  // 3.2. Exchange the attestation to FAC token.
                  [self.APIService attestKeyWithAttestation:result.attestation
                                                      keyID:result.keyID
                                                  challenge:result.challenge
                                                 limitedUse:limitedUse]
                ];

                return [FBLPromise onQueue:self.queue all:attestationResults];
              })
      .recoverOn(self.queue, ^id(NSError *error) {
        // If App Attest attestation was rejected then reset the attestation and throw a specific
        // error.
        GACAppCheckHTTPError *HTTPError = (GACAppCheckHTTPError *)error;
        if ([HTTPError isKindOfClass:[GACAppCheckHTTPError class]] &&
            HTTPError.HTTPResponse.statusCode == 403) {
          GACAppCheckLogDebug(GACLoggerAppCheckMessageCodeAttestationRejected,
                              @"App Attest attestation was rejected by backend. The existing "
                              @"attestation will be reset.");
          // Reset the attestation.
          return [self resetAttestation].thenOn(self.queue, ^NSError *(id result) {
            // Throw the rejection error.
            return [[GACAppAttestRejectionError alloc] initWithUnderlyingError:error];
          });
        }

        // Otherwise just re-throw the error.
        return error;
      });
}

/// Resets stored key ID and attestation artifact.
- (FBLPromise<NSNull *> *)resetAttestation {
  return [self.keyIDStorage setAppAttestKeyID:nil].thenOn(self.queue, ^id(id result) {
    return [self.artifactStorage setArtifact:nil forKey:@""];
  });
}

#pragma mark - Token refresh sequence (assertion)

- (FBLPromise<GACAppCheckToken *> *)refreshTokenWithKeyID:(NSString *)keyID
                                                 artifact:(NSData *)artifact
                                               limitedUse:(BOOL)limitedUse {
  return [self.APIService getRandomChallenge]
      .thenOn(self.queue,
              ^FBLPromise<GACAppAttestAssertionData *> *(NSData *challenge) {
                return [self generateAssertionWithKeyID:keyID
                                               artifact:artifact
                                              challenge:challenge];
              })
      .thenOn(self.queue, ^id(GACAppAttestAssertionData *assertion) {
        return [self.APIService getAppCheckTokenWithArtifact:assertion.artifact
                                                   challenge:assertion.challenge
                                                   assertion:assertion.assertion
                                                  limitedUse:limitedUse];
      });
}

- (FBLPromise<GACAppAttestAssertionData *> *)generateAssertionWithKeyID:(NSString *)keyID
                                                               artifact:(NSData *)artifact
                                                              challenge:(NSData *)challenge {
  // 1. Calculate the statement and its hash for assertion.
  return [FBLPromise
             onQueue:self.queue
                  do:^NSData *_Nullable {
                    // 1.1. Compose statement to generate assertion for.
                    NSMutableData *statementForAssertion = [artifact mutableCopy];
                    [statementForAssertion appendData:challenge];

                    // 1.2. Get the statement SHA256 hash.
                    return [GACAppCheckCryptoUtils sha256HashFromData:[statementForAssertion copy]];
                  }]
      .thenOn(
          self.queue,
          ^FBLPromise<NSData *> *(NSData *statementHash) {
            // 2. Generate App Attest assertion.
            return [FBLPromise onQueue:self.queue
                       wrapObjectOrErrorCompletion:^(
                           FBLPromiseObjectOrErrorCompletion _Nonnull handler) {
                         [self.appAttestService generateAssertion:keyID
                                                   clientDataHash:statementHash
                                                completionHandler:handler];
                       }]
                .recoverOn(self.queue, ^id(NSError *appAttestError) {
                  NSError *error = [GACAppCheckErrorUtil
                      appAttestGenerateAssertionFailedWithError:appAttestError
                                                          keyId:keyID
                                                 clientDataHash:statementHash];

                  // If Apple rejected the key (DCErrorInvalidKey or
                  // DCErrorInvalidInput) then reset the attestation and
                  // throw a specific error to signal retry (GACAppAttestRejectionError).
                  NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
                  if (underlyingError && [underlyingError.domain isEqualToString:DCErrorDomain] &&
                      (underlyingError.code == DCErrorInvalidKey ||
                       underlyingError.code == DCErrorInvalidInput)) {
                    NSString *logMessage = [NSString
                        stringWithFormat:@"App Attest invalid key/input; the existing attestation "
                                         @"will be reset. DC Error Code: %@.",
                                         @(underlyingError.code)];
                    GACAppCheckLog(GACLoggerAppCheckMessageCodeAssertionRejected,
                                   GACAppCheckLogLevelDebug, logMessage);
                    // Reset the attestation.
                    return [self resetAttestation].thenOn(self.queue, ^NSError *(id result) {
                      // Throw the rejection error.
                      return [[GACAppAttestRejectionError alloc] initWithUnderlyingError:error];
                    });
                  }

                  // Otherwise just re-throw the error.
                  return error;
                });
          })
      // 3. Compose the result object.
      .thenOn(self.queue, ^GACAppAttestAssertionData *(NSData *assertion) {
        return [[GACAppAttestAssertionData alloc] initWithChallenge:challenge
                                                           artifact:artifact
                                                          assertion:assertion];
      });
}

#pragma mark - State handling

- (FBLPromise<GACAppAttestProviderState *> *)attestationState {
  dispatch_queue_t stateQueue =
      dispatch_queue_create("GACAppAttestProvider.state", DISPATCH_QUEUE_SERIAL);

  return [FBLPromise
      onQueue:stateQueue
           do:^id _Nullable {
             NSError *error;

             // 1. Check if App Attest is supported.
             id isSupportedResult = FBLPromiseAwait([self isAppAttestSupported], &error);
             if (isSupportedResult == nil) {
               return [[GACAppAttestProviderState alloc] initUnsupportedWithError:error];
             }

             // 2. Check for stored key ID of the generated App Attest key pair.
             NSString *appAttestKeyID =
                 FBLPromiseAwait([self.keyIDStorage getAppAttestKeyID], &error);
             if (appAttestKeyID == nil) {
               return [[GACAppAttestProviderState alloc] initWithSupportedInitialState];
             }

             // 3. Check for stored attestation artifact received from Firebase backend.
             NSData *attestationArtifact =
                 FBLPromiseAwait([self.artifactStorage getArtifactForKey:appAttestKeyID], &error);
             if (attestationArtifact == nil) {
               return [[GACAppAttestProviderState alloc] initWithGeneratedKeyID:appAttestKeyID];
             }

             // 4. A valid App Attest key pair was generated and registered with Firebase
             // backend. Return the corresponding state.
             return [[GACAppAttestProviderState alloc] initWithRegisteredKeyID:appAttestKeyID
                                                                      artifact:attestationArtifact];
           }];
}

#pragma mark - Helpers

/// Returns a resolved promise if App Attest is supported and a rejected promise if it is not.
- (FBLPromise<NSNull *> *)isAppAttestSupported {
  if (self.appAttestService.isSupported) {
    return [FBLPromise resolvedWith:[NSNull null]];
  } else {
    NSError *error = [GACAppCheckErrorUtil unsupportedAttestationProvider:@"AppAttestProvider"];
    FBLPromise *rejectedPromise = [FBLPromise pendingPromise];
    [rejectedPromise reject:error];
    return rejectedPromise;
  }
}

/// Generates a new App Attest key associated with the Firebase app if `storedKeyID == nil`.
- (FBLPromise<NSString *> *)generateAppAttestKeyIDIfNeeded:(nullable NSString *)storedKeyID {
  if (storedKeyID) {
    // The key ID has been fetched already, just return it.
    return [FBLPromise resolvedWith:storedKeyID];
  } else {
    // Generate and save a new key otherwise.
    return [self generateAppAttestKey];
  }
}

/// Generates and stores App Attest key associated with the Firebase app.
- (FBLPromise<NSString *> *)generateAppAttestKey {
  return [FBLPromise onQueue:self.queue
             wrapObjectOrErrorCompletion:^(FBLPromiseObjectOrErrorCompletion _Nonnull handler) {
               [self.appAttestService generateKeyWithCompletionHandler:handler];
             }]
      .recoverOn(self.queue,
                 ^id(NSError *error) {
                   return [GACAppCheckErrorUtil appAttestGenerateKeyFailedWithError:error];
                 })
      .thenOn(self.queue, ^FBLPromise<NSString *> *(NSString *keyID) {
        return [self.keyIDStorage setAppAttestKeyID:keyID];
      });
}

+ (NSString *)storageKeySuffixWithServiceName:(NSString *)serviceName
                                 resourceName:(NSString *)resourceName {
  return [NSString stringWithFormat:@"%@.%@", serviceName, resourceName];
}

@end

NS_ASSUME_NONNULL_END
