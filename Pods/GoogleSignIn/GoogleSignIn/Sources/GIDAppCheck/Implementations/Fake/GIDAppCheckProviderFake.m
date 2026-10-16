// Copyright 2023 Google LLC
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

#import "GoogleSignIn/Sources/GIDAppCheck/Implementations/Fake/GIDAppCheckProviderFake.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <AppCheckCore/GACAppCheckToken.h>

NSUInteger const kGIDAppCheckProviderFakeError = 1;

@interface GIDAppCheckProviderFake ()

@property(nonatomic, strong, nullable) GACAppCheckToken *token;
@property(nonatomic, strong, nullable) NSError *error;

@end

@implementation GIDAppCheckProviderFake

- (instancetype)initWithAppCheckToken:(nullable GACAppCheckToken *)token
                                error:(nullable NSError *)error {
  if (self = [super init]) {
    _token = token;
    _error = error;
  }
  return self;
}

- (void)getTokenWithCompletion:(void (^)(GACAppCheckToken *, NSError * _Nullable))handler {
  dispatch_async(dispatch_get_main_queue(), ^{
    handler(self.token, self.error);
  });
}

- (void)getLimitedUseTokenWithCompletion:(void (^)(GACAppCheckToken *,
                                                   NSError * _Nullable))handler {
  dispatch_async(dispatch_get_main_queue(), ^{
    handler(self.token, self.error);
  });
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
