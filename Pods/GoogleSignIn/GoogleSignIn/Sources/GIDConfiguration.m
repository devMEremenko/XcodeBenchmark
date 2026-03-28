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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDConfiguration.h"

// The key for the clientID property to be used with NSSecureCoding.
static NSString *const kClientIDKey = @"clientID";

// The key for the serverClientID property to be used with NSSecureCoding.
static NSString *const kServerClientIDKey = @"serverClientID";

// The key for the hostedDomain property to be used with NSSecureCoding.
static NSString *const kHostedDomainKey = @"hostedDomain";

// The key for the openIDRealm property to be used with NSSecureCoding.
static NSString *const kOpenIDRealmKey = @"openIDRealm";

NS_ASSUME_NONNULL_BEGIN

@implementation GIDConfiguration

- (instancetype)initWithClientID:(NSString *)clientID {
  return [self initWithClientID:clientID
                 serverClientID:nil
                   hostedDomain:nil
                    openIDRealm:nil];
}

- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID {
  return [self initWithClientID:clientID
                 serverClientID:serverClientID
                   hostedDomain:nil
                    openIDRealm:nil];
}

- (instancetype)initWithClientID:(NSString *)clientID
                  serverClientID:(nullable NSString *)serverClientID
                    hostedDomain:(nullable NSString *)hostedDomain
                     openIDRealm:(nullable NSString *)openIDRealm {
  self = [super init];
  if (self) {
    _clientID = [clientID copy];
    _serverClientID = [serverClientID copy];
    _hostedDomain = [hostedDomain copy];
    _openIDRealm = [openIDRealm copy];
  }
  return self;
}

// Extend NSObject's default description for easier debugging.
- (NSString *)description {
  return [NSString stringWithFormat:
      @"<%@: %p, clientID: %@, serverClientID: %@, hostedDomain: %@, openIDRealm: %@>",
      NSStringFromClass([self class]),
      self,
      _clientID,
      _serverClientID,
      _hostedDomain,
      _openIDRealm];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  // Instances of this class are immutable so return a reference to the original per NSCopying docs.
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  NSString *clientID = [coder decodeObjectOfClass:[NSString class] forKey:kClientIDKey];
  NSString *serverClientID = [coder decodeObjectOfClass:[NSString class] forKey:kServerClientIDKey];
  NSString *hostedDomain = [coder decodeObjectOfClass:[NSString class] forKey:kHostedDomainKey];
  NSString *openIDRealm = [coder decodeObjectOfClass:[NSString class] forKey:kOpenIDRealmKey];

  // We must have a client ID.
  if (!clientID) {
    return nil;
  }

  return [self initWithClientID:clientID
                 serverClientID:serverClientID
                   hostedDomain:hostedDomain
                    openIDRealm:openIDRealm];
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:_clientID forKey:kClientIDKey];
  [coder encodeObject:_serverClientID forKey:kServerClientIDKey];
  [coder encodeObject:_hostedDomain forKey:kHostedDomainKey];
  [coder encodeObject:_openIDRealm forKey:kOpenIDRealmKey];
}

@end

NS_ASSUME_NONNULL_END
