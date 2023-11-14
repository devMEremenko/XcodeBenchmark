/* Copyright 2014 Google Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GTMSessionFetcher/GTMSessionFetcherService.h"

// Internal methods from GTMSessionFetcherService, not intended for public use.

@interface GTMSessionFetcherService (Internal)

// Methods for use by the fetcher class only.
- (nullable NSURLSession *)session;
- (nullable NSURLSession *)sessionWithCreationBlock:
    (nonnull NS_NOESCAPE GTMSessionFetcherSessionCreationBlock)creationBlock;
- (nullable id<NSURLSessionDelegate>)sessionDelegate;
- (nullable NSDate *)stoppedAllFetchersDate;
- (void)fetcherDidStop:(nonnull GTMSessionFetcher *)fetcher callbacksPending: (BOOL)callbacksPending;

@end
