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

#import "GoogleSignIn/Sources/GIDScopes.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kEmailScope = @"email";
static NSString *const kOldEmailScope = @"https://www.googleapis.com/auth/userinfo.email";
static NSString *const kProfileScope = @"profile";
static NSString *const kOldProfileScope = @"https://www.googleapis.com/auth/userinfo.profile";

static BOOL hasProfile(NSString *scope) {
  return [scope isEqualToString:kProfileScope] || [scope isEqualToString:kOldProfileScope];
}

static BOOL hasEmail(NSString *scope) {
  return [scope isEqualToString:kEmailScope] || [scope isEqualToString:kOldEmailScope];
}

// Checks whether |scopes| contains or implies a particular scope, using
// |hasScope| as the predicate.
static BOOL hasScopeInArray(NSArray *scopes, BOOL (*hasScope)(NSString *)) {
  for (NSString *scope in scopes) {
    if (hasScope(scope)) {
      return YES;
    }
  }
  return NO;
}

// Adds |scopeToAdd| to |originalScopes| if it is not already contained
// or implied, using |hasScope| as the predicate.
static NSArray *addScopeTo(NSArray *originalScopes,
                           BOOL (*hasScope)(NSString *),
                           NSString *scopeToAdd) {
  if (hasScopeInArray(originalScopes, hasScope)) {
    return originalScopes;
  }
  NSMutableArray *result = [NSMutableArray arrayWithArray:originalScopes];
  [result addObject:scopeToAdd];
  return result;
}

@implementation GIDScopes

+ (NSArray *)scopesWithBasicProfile:(NSArray *)scopes {
  scopes = addScopeTo(scopes, hasEmail, kEmailScope);
  return addScopeTo(scopes, hasProfile, kProfileScope);
}

@end

NS_ASSUME_NONNULL_END
