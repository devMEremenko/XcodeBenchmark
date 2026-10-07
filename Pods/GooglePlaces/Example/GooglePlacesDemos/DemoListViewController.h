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

#import <UIKit/UIKit.h>

#import "GooglePlacesDemos/DemoData.h"

/** The class which displays the list of demos. */
@interface DemoListViewController : UITableViewController

/**
 * Construct a new list controller using the provided demo data.
 *
 * @param demoData The demo data to display in the list.
 */
- (instancetype)initWithDemoData:(DemoData *)demoData;

@end
