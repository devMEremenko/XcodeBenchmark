// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/GIDAuthStateMigration.h"

#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

#ifdef SWIFT_PACKAGE
@import AppAuth;
@import GTMAppAuth;
#else
#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMAppAuth/GTMKeychain.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// User preference key to detect whether or not the migration check has been performed.
static NSString *const kMigrationCheckPerformedKey = @"GID_MigrationCheckPerformed";

// Keychain account used to store additional state in SDKs previous to v5, including GPPSignIn.
static NSString *const kOldKeychainAccount = @"GooglePlus";

// The value used for the kSecAttrGeneric key by GTMAppAuth and GTMOAuth2.
static NSString *const kGenericAttribute = @"OAuth";

// Keychain service name used to store the last used fingerprint value.
static NSString *const kFingerprintService = @"fingerprint";

@implementation GIDAuthStateMigration

+ (void)migrateIfNeededWithTokenURL:(NSURL *)tokenURL
                       callbackPath:(NSString *)callbackPath
                       keychainName:(NSString *)keychainName
                     isFreshInstall:(BOOL)isFreshInstall {
  // See if we've performed the migration check previously.
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  if ([defaults boolForKey:kMigrationCheckPerformedKey]) {
    return;
  }

  // If this is not a fresh install, attempt to migrate state.  If this is a fresh install, take no
  // action and go on to mark the migration check as having been performed.
  if (!isFreshInstall) {
    // Attempt migration
    GTMAppAuthFetcherAuthorization *authorization =
        [self extractAuthorizationWithTokenURL:tokenURL callbackPath:callbackPath];

    // If migration was successful, save our migrated state to the keychain.
    if (authorization) {
      // If we're unable to save to the keychain, return without marking migration performed.
      if (![GTMAppAuthFetcherAuthorization saveAuthorization:authorization
                                           toKeychainForName:keychainName]) {
        return;
      };
    }
  }

  // Mark the migration check as having been performed.
  [defaults setBool:YES forKey:kMigrationCheckPerformedKey];
}

// Returns a |GTMAppAuthFetcherAuthorization| object containing any old auth state or |nil| if none
// was found or the migration failed.
+ (nullable GTMAppAuthFetcherAuthorization *)
    extractAuthorizationWithTokenURL:(NSURL *)tokenURL callbackPath:(NSString *)callbackPath {
  // Retrieve the last used fingerprint.
  NSString *fingerprint = [GIDAuthStateMigration passwordForService:kFingerprintService];
  if (!fingerprint) {
    return nil;
  }

  // Retrieve the GTMOAuth2 persistence string.
  NSString *GTMOAuth2PersistenceString = [GTMKeychain passwordFromKeychainForName:fingerprint];
  if (!GTMOAuth2PersistenceString) {
    return nil;
  }

  // Parse the fingerprint.
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  NSString *pattern =
      [NSString stringWithFormat:@"^%@-(.+)-(?:email|profile|https:\\/\\/).*$", bundleID];
  NSError *error;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
  NSRange matchRange = NSMakeRange(0, fingerprint.length);
  NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:fingerprint
                                                            options:0
                                                              range:matchRange];
  if ([matches count] != 1) {
    return nil;
  }

  // Extract the client ID from the fingerprint.
  NSString *clientID = [fingerprint substringWithRange:[matches[0] rangeAtIndex:1]];

  // Generate the redirect URI from the extracted client ID.
  NSString *scheme =
      [[[GIDSignInCallbackSchemes alloc] initWithClientIdentifier:clientID] clientIdentifierScheme];
  NSString *redirectURI = [NSString stringWithFormat:@"%@:%@", scheme, callbackPath];

  // Retrieve the additional token request parameters value.
  NSString *additionalTokenRequestParametersService =
      [NSString stringWithFormat:@"%@~~atrp", fingerprint];
  NSString *additionalTokenRequestParameters =
      [GIDAuthStateMigration passwordForService:additionalTokenRequestParametersService];

  // Generate a persistence string that includes additional token request parameters if present.
  NSString *persistenceString = GTMOAuth2PersistenceString;
  if (additionalTokenRequestParameters) {
    persistenceString = [NSString stringWithFormat:@"%@&%@",
                         GTMOAuth2PersistenceString,
                         additionalTokenRequestParameters];
  }

  // Use |GTMOAuth2KeychainCompatibility| to generate a |GTMAppAuthFetcherAuthorization| from the
  // persistence string, redirect URI, client ID, and token endpoint URL.
  GTMAppAuthFetcherAuthorization *authorization = [GTMOAuth2KeychainCompatibility
      authorizeFromPersistenceString:persistenceString
                            tokenURL:tokenURL
                         redirectURI:redirectURI
                            clientID:clientID
                        clientSecret:nil];

  return authorization;
}

// Returns the password string for a given service string stored by an old version of the SDK or
// |nil| if no matching keychain item was found.
+ (nullable NSString *)passwordForService:(NSString *)service {
  if (!service.length) {
    return nil;
  }
  CFDataRef result = NULL;
  NSDictionary<id, id> *query = @{
    (id)kSecClass : (id)kSecClassGenericPassword,
    (id)kSecAttrGeneric : kGenericAttribute,
    (id)kSecAttrAccount : kOldKeychainAccount,
    (id)kSecAttrService : service,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne,
  };
  OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result);
  NSData *passwordData;
  if (status == noErr && [(__bridge NSData *)result length] > 0) {
    passwordData = [(__bridge NSData *)result copy];
  }
  if (result != NULL) {
    CFRelease(result);
  }
  if (!passwordData) {
    return nil;
  }
  NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
  return password;
}

@end

NS_ASSUME_NONNULL_END
