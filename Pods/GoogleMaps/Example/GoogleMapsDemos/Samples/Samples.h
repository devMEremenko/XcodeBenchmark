/*
 * Copyright 2016 Google LLC. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Type defining the sample definition returned from +newDemo:withTitle:andDescription:. */
typedef NSDictionary<NSString *, id> DemoDefinition;

/** This class defines the list of sample demos included in this app. */
@interface Samples : NSObject

/** Returns a list of section names into which sample demos should be grouped. */
+ (NSArray<NSString *> *)loadSections;

/** Returns one list of sample demos for each section. */
+ (NSArray<NSArray<DemoDefinition *> *> *)loadDemos;

+ (DemoDefinition *)newDemo:(Class)viewControllerClass
                  withTitle:(NSString *)title
             andDescription:(nullable NSString *)description;
@end

NS_ASSUME_NONNULL_END
