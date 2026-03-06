// Copyright 2022 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDGoogleUser.h"

#import "GoogleSignIn/Sources/GIDGoogleUser_Private.h"

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"
#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDSignIn.h"

#import "GoogleSignIn/Sources/GIDAuthentication.h"
#import "GoogleSignIn/Sources/GIDEMMSupport.h"
#import "GoogleSignIn/Sources/GIDProfileData_Private.h"
#import "GoogleSignIn/Sources/GIDSignIn_Private.h"
#import "GoogleSignIn/Sources/GIDSignInPreferences.h"
#import "GoogleSignIn/Sources/GIDToken_Private.h"

@import GTMAppAuth;

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// The ID Token claim key for the hosted domain value.
static NSString *const kHostedDomainIDTokenClaimKey = @"hd";

// Key constants used for encode and decode.
static NSString *const kProfileDataKey = @"profileData";
static NSString *const kAuthStateKey = @"authState";

// Parameters for the token exchange endpoint.
static NSString *const kAudienceParameter = @"audience";
static NSString *const kOpenIDRealmParameter = @"openid.realm";

// Additional parameter names for EMM.
static NSString *const kEMMSupportParameterName = @"emm_support";

// Minimal time interval before expiration for the access token or it needs to be refreshed.
static NSTimeInterval const kMinimalTimeToExpire = 60.0;

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@interface GIDGoogleUser ()

@property (nonatomic, strong) id<GTMAuthSessionDelegate> authSessionDelegate;

@end
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

@implementation GIDGoogleUser {
  GIDConfiguration *_cachedConfiguration;
  
  // A queue for pending token refresh handlers so we don't fire multiple requests in parallel.
  // Access to this ivar should be synchronized.
  NSMutableArray<GIDGoogleUserCompletion> *_tokenRefreshHandlerQueue;
}

- (nullable NSString *)userID {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.subject) {
      return [idTokenDecoded.subject copy];
    }
  }
  return nil;
}

- (nullable NSArray<NSString *> *)grantedScopes {
  NSArray<NSString *> *grantedScopes;
  NSString *grantedScopeString = self.authState.lastTokenResponse.scope;
  if (grantedScopeString) {
    // If we have a 'scope' parameter from the backend, this is authoritative.
    // Remove leading and trailing whitespace.
    grantedScopeString = [grantedScopeString stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
    // Tokenize with space as a delimiter.
    NSMutableArray<NSString *> *parsedScopes =
        [[grantedScopeString componentsSeparatedByString:@" "] mutableCopy];
    // Remove empty strings.
    [parsedScopes removeObject:@""];
    grantedScopes = [parsedScopes copy];
  }
  return grantedScopes;
}

- (GIDConfiguration *)configuration {
  @synchronized(self) {
    // Caches the configuration since it would not change for one GIDGoogleUser instance.
    if (!_cachedConfiguration) {
      NSString *clientID = self.authState.lastAuthorizationResponse.request.clientID;
      NSString *serverClientID =
          self.authState.lastTokenResponse.request.additionalParameters[kAudienceParameter];
      NSString *openIDRealm =
          self.authState.lastTokenResponse.request.additionalParameters[kOpenIDRealmParameter];
      
      _cachedConfiguration = [[GIDConfiguration alloc] initWithClientID:clientID
                                                         serverClientID:serverClientID
                                                           hostedDomain:[self hostedDomain]
                                                            openIDRealm:openIDRealm];
    };
  }
  return _cachedConfiguration;
}

- (void)refreshTokensIfNeededWithCompletion:(GIDGoogleUserCompletion)completion {
  if (!([self.accessToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire ||
      (self.idToken && [self.idToken.expirationDate timeIntervalSinceNow] < kMinimalTimeToExpire))) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(self, nil);
    });
    return;
  }
  @synchronized (_tokenRefreshHandlerQueue) {
    // Push the handler into the callback queue.
    [_tokenRefreshHandlerQueue addObject:[completion copy]];
    if (_tokenRefreshHandlerQueue.count > 1) {
      // This is not the first handler in the queue, no fetch is needed.
      return;
    }
  }
  // This is the first handler in the queue, a fetch is needed.
  NSMutableDictionary *additionalParameters = [@{} mutableCopy];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      [GIDEMMSupport updatedEMMParametersWithParameters:
          self.authState.lastTokenResponse.request.additionalParameters]];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
  [additionalParameters addEntriesFromDictionary:
      self.authState.lastTokenResponse.request.additionalParameters];
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  additionalParameters[kSDKVersionLoggingParameter] = GIDVersion();
  additionalParameters[kEnvironmentLoggingParameter] = GIDEnvironment();

  OIDTokenRequest *tokenRefreshRequest =
      [self.authState tokenRefreshRequestWithAdditionalParameters:additionalParameters];
  [OIDAuthorizationService performTokenRequest:tokenRefreshRequest
                 originalAuthorizationResponse:self.authState.lastAuthorizationResponse
                                      callback:^(OIDTokenResponse *_Nullable tokenResponse,
                                                 NSError *_Nullable error) {
    if (tokenResponse) {
      [self.authState updateWithTokenResponse:tokenResponse error:nil];
    } else {
      if (error.domain == OIDOAuthTokenErrorDomain) {
        [self.authState updateWithAuthorizationError:error];
      }
    }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    [GIDEMMSupport handleTokenFetchEMMError:error completion:^(NSError *_Nullable error) {
      // Process the handler queue to call back.
      NSArray<GIDGoogleUserCompletion> *refreshTokensHandlerQueue;
      @synchronized(self->_tokenRefreshHandlerQueue) {
        refreshTokensHandlerQueue = [self->_tokenRefreshHandlerQueue copy];
        [self->_tokenRefreshHandlerQueue removeAllObjects];
      }
      for (GIDGoogleUserCompletion completion in refreshTokensHandlerQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completion(error ? nil : self, error);
        });
      }
    }];
#elif TARGET_OS_OSX || TARGET_OS_MACCATALYST
    NSArray<GIDGoogleUserCompletion> *refreshTokensHandlerQueue;
    @synchronized(self->_tokenRefreshHandlerQueue) {
      refreshTokensHandlerQueue = [self->_tokenRefreshHandlerQueue copy];
      [self->_tokenRefreshHandlerQueue removeAllObjects];
    }
    for (GIDGoogleUserCompletion completion in refreshTokensHandlerQueue) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(error ? nil : self, error);
      });
    }
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
  }];
}

- (OIDAuthState *)authState {
  return ((GTMAuthSession *)self.fetcherAuthorizer).authState;
}

- (void)addScopes:(NSArray<NSString *> *)scopes
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
    presentingViewController:(UIViewController *)presentingViewController
#elif TARGET_OS_OSX
            presentingWindow:(NSWindow *)presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                  completion:(nullable void (^)(GIDSignInResult *_Nullable signInResult,
                                                NSError *_Nullable error))completion {
  if (self != GIDSignIn.sharedInstance.currentUser) {
    NSError *error = [NSError errorWithDomain:kGIDSignInErrorDomain
                                         code:kGIDSignInErrorCodeMismatchWithCurrentUser
                                     userInfo:nil];
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completion(nil, error);
      });
    }
    return;
  }
  
  [GIDSignIn.sharedInstance addScopes:scopes
#if TARGET_OS_IOS || TARGET_OS_MACCATALYST
             presentingViewController:presentingViewController
#elif TARGET_OS_OSX
                     presentingWindow:presentingWindow
#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
                           completion:completion];
}

#pragma mark - Private Methods

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
- (nullable NSString *)emmSupport {
  return self.authState.lastAuthorizationResponse
      .request.additionalParameters[kEMMSupportParameterName];
}
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST

- (instancetype)initWithAuthState:(OIDAuthState *)authState
                      profileData:(nullable GIDProfileData *)profileData {
  self = [super init];
  if (self) {
    _tokenRefreshHandlerQueue = [[NSMutableArray alloc] init];
    _profile = profileData;
    
    GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    _authSessionDelegate = [[GIDEMMSupport alloc] init];
    authSession.delegate = _authSessionDelegate;
#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    authSession.authState.stateChangeDelegate = self;
    _fetcherAuthorizer = authSession;
    
    [self updateTokensWithAuthState:authState];
  }
  return self;
}

- (void)updateWithTokenResponse:(OIDTokenResponse *)tokenResponse
          authorizationResponse:(OIDAuthorizationResponse *)authorizationResponse
                    profileData:(nullable GIDProfileData *)profileData {
  @synchronized(self) {
    _profile = profileData;
    
    // We don't want to trigger the delegate before we update authState completely. So we unset the
    // delegate before the first update. Also the order of updates is important because
    // `updateWithAuthorizationResponse` would clear the last token reponse and refresh token.
    // TODO: Rewrite authState update logic when the issue is addressed.(openid/AppAuth-iOS#728)
    self.authState.stateChangeDelegate = nil;
    [self.authState updateWithAuthorizationResponse:authorizationResponse error:nil];
    self.authState.stateChangeDelegate = self;
    [self.authState updateWithTokenResponse:tokenResponse error:nil];
  }
}

- (void)updateTokensWithAuthState:(OIDAuthState *)authState {
  GIDToken *accessToken =
      [[GIDToken alloc] initWithTokenString:authState.lastTokenResponse.accessToken
                             expirationDate:authState.lastTokenResponse.accessTokenExpirationDate];
  if (![self.accessToken isEqualToToken:accessToken]) {
    self.accessToken = accessToken;
  }
  
  GIDToken *refreshToken = [[GIDToken alloc] initWithTokenString:authState.refreshToken
                                                  expirationDate:nil];
  if (![self.refreshToken isEqualToToken:refreshToken]) {
    self.refreshToken = refreshToken;
  }
  
  GIDToken *idToken;
  NSString *idTokenString = authState.lastTokenResponse.idToken;
  if (idTokenString) {
    NSDate *idTokenExpirationDate =
        [[[OIDIDToken alloc] initWithIDTokenString:idTokenString] expiresAt];
    idToken = [[GIDToken alloc] initWithTokenString:idTokenString
                                     expirationDate:idTokenExpirationDate];
  } else {
    idToken = nil;
  }
  if ((self.idToken || idToken) && ![self.idToken isEqualToToken:idToken]) {
    self.idToken = idToken;
  }
}

#pragma mark - Helpers

- (nullable NSString *)hostedDomain {
  NSString *idTokenString = self.idToken.tokenString;
  if (idTokenString) {
    OIDIDToken *idTokenDecoded = [[OIDIDToken alloc] initWithIDTokenString:idTokenString];
    if (idTokenDecoded && idTokenDecoded.claims[kHostedDomainIDTokenClaimKey]) {
      return idTokenDecoded.claims[kHostedDomainIDTokenClaimKey];
    }
  }
  return nil;
}

#pragma mark - OIDAuthStateChangeDelegate

- (void)didChangeState:(OIDAuthState *)state {
   [self updateTokensWithAuthState:state];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    GIDProfileData *profile =
        [decoder decodeObjectOfClass:[GIDProfileData class] forKey:kProfileDataKey];
    
    OIDAuthState *authState;
    if ([decoder containsValueForKey:kAuthStateKey]) { // Current encoding
      authState = [decoder decodeObjectOfClass:[OIDAuthState class] forKey:kAuthStateKey];
    } else { // Old encoding
      GIDAuthentication *authentication = [decoder decodeObjectOfClass:[GIDAuthentication class]
                                                                forKey:@"authentication"];
      authState = authentication.authState;
    }
    
    self = [self initWithAuthState:authState profileData:profile];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_profile forKey:kProfileDataKey];
  [encoder encodeObject:self.authState forKey:kAuthStateKey];
}

@end

NS_ASSUME_NONNULL_END
