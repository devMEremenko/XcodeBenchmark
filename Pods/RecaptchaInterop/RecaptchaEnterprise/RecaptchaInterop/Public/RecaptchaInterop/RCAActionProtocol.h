// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Action intended to be protected by reCAPTCHA. An instance of this object
 * should be passed to RecaptchaClient.execute.
 */
@protocol RCAActionProtocol

/** Indicates that the protected action is a Login workflow. */
@property(class, readonly, nonatomic) id<RCAActionProtocol> login;

/** Indicates that the protected action is a Signup workflow. */
@property(class, readonly, nonatomic) id<RCAActionProtocol> signup;

/** A String representing the action. */
@property(nonatomic, readonly) NSString* action;

/** Creates an instance with a custom action from a String. */
- (instancetype)initWithCustomAction:(NSString*)customAction;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
