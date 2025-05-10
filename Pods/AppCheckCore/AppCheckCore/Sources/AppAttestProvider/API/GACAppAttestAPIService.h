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

@class FBLPromise<Result>;
@class GACAppAttestAttestationResponse;
@class GACAppCheckToken;
@protocol GACAppCheckAPIServiceProtocol;

NS_ASSUME_NONNULL_BEGIN

/// Methods to send API requests required for App Attest based attestation sequence.
@protocol GACAppAttestAPIServiceProtocol <NSObject>

/// Request a random challenge from server.
- (FBLPromise<NSData *> *)getRandomChallenge;

/// Sends attestation data to the App Check backend for validation.
/// @param attestation The App Attest key attestation data obtained from the method
/// `-[DCAppAttestService attestKey:clientDataHash:completionHandler:]` using the random challenge
/// received from App Check backend.
/// @param keyID The key ID used to generate the attestation.
/// @param challenge The challenge used to generate the attestation.
/// @return A promise that is fulfilled with a response object with an encrypted attestation
/// artifact and an App Check token or rejected with an error.
- (FBLPromise<GACAppAttestAttestationResponse *> *)attestKeyWithAttestation:(NSData *)attestation
                                                                      keyID:(NSString *)keyID
                                                                  challenge:(NSData *)challenge
                                                                 limitedUse:(BOOL)limitedUse;

/// Exchanges attestation data (artifact & assertion) and a challenge for a FAC token.
- (FBLPromise<GACAppCheckToken *> *)getAppCheckTokenWithArtifact:(NSData *)artifact
                                                       challenge:(NSData *)challenge
                                                       assertion:(NSData *)assertion
                                                      limitedUse:(BOOL)limitedUse;

@end

/// A default implementation of `GACAppAttestAPIServiceProtocol`.
@interface GACAppAttestAPIService : NSObject <GACAppAttestAPIServiceProtocol>

/// Default initializer.
///
/// @param APIService An instance implementing `GACAppCheckAPIServiceProtocol` to be used to send
/// network requests to the App Check backend.
/// @param resourceName The name of the resource protected by App Check; for a Firebase App this is
/// "projects/{project_id}/apps/{app_id}".
- (instancetype)initWithAPIService:(id<GACAppCheckAPIServiceProtocol>)APIService
                      resourceName:(NSString *)resourceName NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
