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

NS_ASSUME_NONNULL_BEGIN

/**
 * An object to obtain and describe the device passcode state.
 */
@interface GIDMDMPasscodeState : NSObject

/**
 * The device passcode status.
 */
@property(nonatomic, strong, readonly, nullable) NSString *status;

/**
 * The detailed device passcode information encoded as a string.
 * See go/robust-ios-mdmlite for its format.
 */
@property(nonatomic, strong, readonly, nullable) NSString *info;

/**
 * This class should not be initialized from other code.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a new instance for the class that represents the current passcode state.
 */
+ (instancetype)passcodeState;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
