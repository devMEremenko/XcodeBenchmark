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

#import "GooglePlacesDemos/DemoData.h"

#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteModalViewController.h"
#import "GooglePlacesDemos/Samples/Autocomplete/AutocompletePushViewController.h"
#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteWithCustomColors.h"
#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteWithSearchViewController.h"
#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteWithTextFieldController.h"
#import "GooglePlacesDemos/Samples/FindPlaceLikelihoodListViewController.h"
#import "GooglePlacesDemos/Support/BaseDemoViewController.h"

@implementation Demo {
  Class _viewControllerClass;
}

- (instancetype)initWithViewControllerClass:(Class)viewControllerClass {
  if ((self = [self init])) {
    _title = [viewControllerClass demoTitle];
    _viewControllerClass = viewControllerClass;
  }
  return self;
}

- (UIViewController *)createViewControllerWithAutocompleteFilter:
                          (GMSAutocompleteFilter *)autocompleteFilter
                                                     placeFields:(GMSPlaceField)placeFields {
  // Construct the demo view controller.
  UIViewController *demoViewController = [[_viewControllerClass alloc] init];

  // Pass the place fields to the view controller for these classes.
  if ([demoViewController isKindOfClass:[AutocompleteBaseViewController class]]) {
    AutocompleteBaseViewController *controller =
        (AutocompleteBaseViewController *)demoViewController;
    controller.autocompleteFilter = autocompleteFilter;
    controller.placeFields = placeFields;
  }

  return demoViewController;
}

@end

@implementation DemoSection

- (instancetype)initWithTitle:(NSString *)title demos:(NSArray<Demo *> *)demos {
  if ((self = [self init])) {
    _title = [title copy];
    _demos = [demos copy];
  }
  return self;
}

@end

@implementation DemoData

- (instancetype)init {
  if ((self = [super init])) {
    NSArray<Demo *> *autocompleteDemos = @[
      [[Demo alloc] initWithViewControllerClass:[AutocompleteWithCustomColors class]],
      [[Demo alloc] initWithViewControllerClass:[AutocompleteModalViewController class]],
      [[Demo alloc] initWithViewControllerClass:[AutocompletePushViewController class]],
      [[Demo alloc] initWithViewControllerClass:[AutocompleteWithSearchViewController class]],
      [[Demo alloc] initWithViewControllerClass:[AutocompleteWithTextFieldController class]],
    ];

    NSArray<Demo *> *findPlaceLikelihoodDemos = @[ [[Demo alloc]
        initWithViewControllerClass:[FindPlaceLikelihoodListViewController class]] ];

    _sections = @[
      [[DemoSection alloc]
          initWithTitle:NSLocalizedString(@"Demo.Section.Title.Autocomplete",
                                          @"Title of the autocomplete demo section")
                  demos:autocompleteDemos],
      [[DemoSection alloc]
          initWithTitle:NSLocalizedString(@"Demo.Section.Title.FindPlaceLikelihood",
                                          @"Title of the findPlaceLikelihood demo section")
                  demos:findPlaceLikelihoodDemos]
    ];
  }
  return self;
}

- (Demo *)firstDemo {
  return _sections[0].demos[0];
}

@end
