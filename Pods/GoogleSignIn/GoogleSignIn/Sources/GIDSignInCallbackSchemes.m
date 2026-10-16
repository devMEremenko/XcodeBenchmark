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

#import "GoogleSignIn/Sources/GIDSignInCallbackSchemes.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GIDSignInCallbackSchemes {
  NSString *_clientIdentifier;
}

/**
 * @fn relevantURLSchemes
 * @brief Extracts CFBundleURLSchemes from the host app's info.plist.
 * @return An array of lowercase NSString *'s representing the URL schemes the host app has declared
 *     support for.
 * @remarks Branched from google3/googlemac/iPhone/Firebase/Source/GGLBundleUtil.m
 */
+ (NSArray *)relevantURLSchemes {
  NSMutableArray *result = [NSMutableArray array];
  NSBundle *bundle = [NSBundle mainBundle];
  NSArray *urlTypes = [bundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  for (NSDictionary *urlType in urlTypes) {
    NSArray *urlTypeSchemes = urlType[@"CFBundleURLSchemes"];
    for (NSString *urlTypeScheme in urlTypeSchemes) {
      [result addObject:urlTypeScheme.lowercaseString];
    }
  }
  return result;
}

- (instancetype)initWithClientIdentifier:(NSString *)clientIdentifier {
  self = [super init];
  if (self) {
    _clientIdentifier = [clientIdentifier copy];
  }
  return self;
}

- (NSString *)clientIdentifierScheme {
  NSArray *clientIdentifierParts = [_clientIdentifier componentsSeparatedByString:@"."];
  NSString *reversedClientIdentifier =
      [[clientIdentifierParts reverseObjectEnumerator].allObjects componentsJoinedByString:@"."];
  return reversedClientIdentifier.lowercaseString;
}

- (NSArray *)allSchemes {
  NSMutableArray *schemes = [NSMutableArray array];
  NSString *clientIdentifierScheme = [self clientIdentifierScheme];
  if (clientIdentifierScheme) {
    [schemes addObject:clientIdentifierScheme];
  }
  return schemes;
}

- (NSMutableArray *)unsupportedSchemes {
  NSMutableArray *unsupportedSchemes = [NSMutableArray arrayWithArray:[self allSchemes]];
  NSArray *supportedSchemes = [[self class] relevantURLSchemes];
  [unsupportedSchemes removeObjectsInArray:supportedSchemes];
  return unsupportedSchemes;
}

- (BOOL)URLSchemeIsCallbackScheme:(NSURL *)URL {
  NSString *incomingURLScheme = URL.scheme.lowercaseString;
  for (NSString *scheme in [self allSchemes]) {
    if ([incomingURLScheme isEqual:scheme]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
