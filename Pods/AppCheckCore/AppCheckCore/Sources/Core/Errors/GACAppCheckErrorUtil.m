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

#import "AppCheckCore/Sources/Core/Errors/GACAppCheckErrorUtil.h"

#import <DeviceCheck/DeviceCheck.h>

#import <GoogleUtilities/GULAppEnvironmentUtil.h>
#import <GoogleUtilities/GULKeychainUtils.h>

#import "AppCheckCore/Sources/Core/Errors/GACAppCheckHTTPError.h"
#import "AppCheckCore/Sources/Public/AppCheckCore/GACAppCheckErrors.h"

@implementation GACAppCheckErrorUtil

+ (NSError *)publicDomainErrorWithError:(NSError *)error {
  if ([error.domain isEqualToString:GACAppCheckErrorDomain]) {
    return error;
  }

  return [self unknownErrorWithError:error];
}

#pragma mark - Internal errors

+ (NSError *)cachedTokenNotFound {
  NSString *failureReason = [NSString stringWithFormat:@"Cached token not found."];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)cachedTokenExpired {
  NSString *failureReason = [NSString stringWithFormat:@"Cached token expired."];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)keychainErrorWithError:(NSError *)error {
  if ([error.domain isEqualToString:kGULKeychainUtilsErrorDomain]) {
    NSString *failureReason = [NSString stringWithFormat:@"Keychain access error."];
    return [self appCheckErrorWithCode:GACAppCheckErrorCodeKeychain
                         failureReason:failureReason
                       underlyingError:error];
  }

  return [self unknownErrorWithError:error];
}

+ (GACAppCheckHTTPError *)APIErrorWithHTTPResponse:(NSHTTPURLResponse *)HTTPResponse
                                              data:(nullable NSData *)data {
  return [[GACAppCheckHTTPError alloc] initWithHTTPResponse:HTTPResponse data:data];
}

+ (NSError *)APIErrorWithNetworkError:(NSError *)networkError {
  NSString *failureReason = [NSString stringWithFormat:@"API request error."];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeServerUnreachable
                       failureReason:failureReason
                     underlyingError:networkError];
}

+ (NSError *)appCheckTokenResponseErrorWithMissingField:(NSString *)fieldName {
  NSString *failureReason = [NSString
      stringWithFormat:@"Unexpected app check token response format. Field `%@` is missing.",
                       fieldName];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)appAttestAttestationResponseErrorWithMissingField:(NSString *)fieldName {
  NSString *failureReason =
      [NSString stringWithFormat:@"Unexpected attestation response format. Field `%@` is missing.",
                                 fieldName];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)JSONSerializationError:(NSError *)error {
  NSString *failureReason = [NSString stringWithFormat:@"JSON serialization error."];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:error];
}

+ (NSError *)unsupportedAttestationProvider:(NSString *)providerName {
  NSString *failureReason = [NSString
      stringWithFormat:
          @"The attestation provider %@ is not supported on current platform and OS version.",
          providerName];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnsupported
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)errorWithFailureReason:(NSString *)failureReason {
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

#pragma mark - App Attest

+ (NSError *)appAttestKeyIDNotFound {
  NSString *failureReason = [NSString stringWithFormat:@"App attest key ID not found."];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:nil];
}

+ (NSError *)appAttestGenerateKeyFailedWithError:(NSError *)error {
  NSString *failureReason =
      [NSString stringWithFormat:@"Failed to generate a new cryptographic key for use with the App "
                                 @"Attest service (`generateKeyWithCompletionHandler:`); %@.",
                                 [self errorDescriptionWithDeviceCheckError:error]];
  // TODO(#31): Add a new error code for this case (e.g., GACAppCheckAppAttestGenerateKeyFailed).
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:error];
}

+ (NSError *)appAttestAttestKeyFailedWithError:(NSError *)error
                                         keyId:(NSString *)keyId
                                clientDataHash:(NSData *)clientDataHash {
  NSString *failureReason =
      [NSString stringWithFormat:@"Failed to attest the validity of the generated cryptographic "
                                 @"key (`attestKey:clientDataHash:completionHandler:`); "
                                 @"keyId.length = %lu, clientDataHash = %@, systemVersion = %@; "
                                 @"%@.",
                                 (unsigned long)keyId.length,
                                 [clientDataHash base64EncodedStringWithOptions:0],
                                 [GULAppEnvironmentUtil systemVersion],
                                 [self errorDescriptionWithDeviceCheckError:error]];
  // TODO(#31): Add a new error code for this case (e.g., GACAppCheckAppAttestAttestKeyFailed).
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:error];
}

+ (NSError *)appAttestGenerateAssertionFailedWithError:(NSError *)error
                                                 keyId:(NSString *)keyId
                                        clientDataHash:(NSData *)clientDataHash {
  NSString *failureReason = [NSString
      stringWithFormat:@"Failed to create a block of data that demonstrates the legitimacy of the "
                       @"app instance (`generateAssertion:clientDataHash:completionHandler:`); "
                       @"keyId.length = %lu, clientDataHash = %@, systemVersion = %@; %@.",
                       (unsigned long)keyId.length,
                       [clientDataHash base64EncodedStringWithOptions:0],
                       [GULAppEnvironmentUtil systemVersion],
                       [self errorDescriptionWithDeviceCheckError:error]];
  // TODO(#31): Add error code for this case (e.g., GACAppCheckAppAttestGenerateAssertionFailed).
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:error];
}

#pragma mark - Helpers

+ (NSError *)unknownErrorWithError:(NSError *)error {
  NSString *failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey];
  return [self appCheckErrorWithCode:GACAppCheckErrorCodeUnknown
                       failureReason:failureReason
                     underlyingError:error];
}

+ (NSError *)appCheckErrorWithCode:(GACAppCheckErrorCode)code
                     failureReason:(nullable NSString *)failureReason
                   underlyingError:(nullable NSError *)underlyingError {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  userInfo[NSUnderlyingErrorKey] = underlyingError;
  userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;

  return [NSError errorWithDomain:GACAppCheckErrorDomain code:code userInfo:userInfo];
}

+ (NSString *)errorDescriptionWithDeviceCheckError:(NSError *)error {
  // DCError is only available on iOS 11.0+, macOS 10.15+, Mac Catalyst 13.1+, tvOS 11.0+ and
  // watchOS 9.0+.
  if (@available(macOS 10.15, macCatalyst 13.1, watchOS 9.0, *)) {
    if ([error.domain isEqualToString:DCErrorDomain]) {
      DCError errorCode = error.code;
      switch (errorCode) {
        case DCErrorFeatureUnsupported:
          return @"DCErrorFeatureUnsupported - DeviceCheck is unavailable on this device";
        case DCErrorInvalidInput:
          return @"DCErrorInvalidInput - An error code that indicates when your app provides data "
                 @"that isn’t formatted correctly";
        case DCErrorInvalidKey:
          return @"DCErrorInvalidKey - An error caused by a failed attempt to use the App Attest "
                 @"key";
        case DCErrorServerUnavailable:
          return @"DCErrorServerUnavailable - An error that indicates a failed attempt to contact "
                 @"the App Attest service during an attestation";
        case DCErrorUnknownSystemFailure:
          return @"DCErrorUnknownSystemFailure - A failure has occurred, such as the failure to "
                 @"generate a token";
        default:
          return [NSString stringWithFormat:@"Unknown DCError(%ld) - %@", (long)errorCode,
                                            error.localizedDescription];
      }
    }
  }

  // Not a DeviceCheck error or DCError is not available on the platform.
  return [NSString stringWithFormat:@"Unknown Error { domain: %@, code: %ld } - %@", error.domain,
                                    (long)error.code, error.localizedDescription];
}

@end

void GACAppCheckSetErrorToPointer(NSError *error, NSError **pointer) {
  if (pointer != NULL) {
    *pointer = error;
  }
}
