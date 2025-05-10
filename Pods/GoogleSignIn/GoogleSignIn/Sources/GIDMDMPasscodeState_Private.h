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
#import <TargetConditionals.h>

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <Foundation/Foundation.h>

#import "GoogleSignIn/Sources/GIDMDMPasscodeState.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal interface for the GIDMDMPasscodeState class.
 */
@interface GIDMDMPasscodeState ()

/**
 * Initializes the instance with the data.
 */
- (instancetype)initWithStatus:(NSString *)status info:(NSString *)info;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
