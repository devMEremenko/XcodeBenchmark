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

@class GACAppCheckHTTPError;

NS_ASSUME_NONNULL_BEGIN

void GACAppCheckSetErrorToPointer(NSError *error, NSError **pointer);

@interface GACAppCheckErrorUtil : NSObject

+ (NSError *)publicDomainErrorWithError:(NSError *)error;

// MARK: - Internal errors

+ (NSError *)cachedTokenNotFound;

+ (NSError *)cachedTokenExpired;

+ (NSError *)keychainErrorWithError:(NSError *)error;

+ (GACAppCheckHTTPError *)APIErrorWithHTTPResponse:(NSHTTPURLResponse *)HTTPResponse
                                              data:(nullable NSData *)data;

+ (NSError *)APIErrorWithNetworkError:(NSError *)networkError;

+ (NSError *)appCheckTokenResponseErrorWithMissingField:(NSString *)fieldName;

+ (NSError *)appAttestAttestationResponseErrorWithMissingField:(NSString *)fieldName;

+ (NSError *)JSONSerializationError:(NSError *)error;

+ (NSError *)errorWithFailureReason:(NSString *)failureReason;

+ (NSError *)unsupportedAttestationProvider:(NSString *)providerName;

// MARK: - App Attest Errors

+ (NSError *)appAttestKeyIDNotFound;

+ (NSError *)appAttestGenerateKeyFailedWithError:(NSError *)error;

+ (NSError *)appAttestAttestKeyFailedWithError:(NSError *)error
                                         keyId:(NSString *)keyId
                                clientDataHash:(NSData *)clientDataHash;

+ (NSError *)appAttestGenerateAssertionFailedWithError:(NSError *)error
                                                 keyId:(NSString *)keyId
                                        clientDataHash:(NSData *)clientDataHash;

@end

NS_ASSUME_NONNULL_END
