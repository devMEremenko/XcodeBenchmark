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

// The handler for displaying EMM-specific errors to users.
@interface GIDEMMErrorHandler : NSObject

// Retrieve the shared instance of this class.
+ (instancetype)sharedInstance;

// Handles EMM specific error that is returned in server response.
// Returns whether or not an EMM-specific error is being handled by this invocation.
// If the return value is |YES|, |completion| will be called asynchronously in the main thread
// after the user interacts with the error dialog;
// if the return value is |NO|, |completion| will be called before returning.
- (BOOL)handleErrorFromResponse:(NSDictionary<NSString *, id> *)response
                     completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
