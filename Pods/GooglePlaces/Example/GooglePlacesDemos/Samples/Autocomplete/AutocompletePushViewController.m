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

#import "GooglePlacesDemos/Samples/Autocomplete/AutocompletePushViewController.h"

#import <GooglePlaces/GooglePlaces.h>

@interface AutocompletePushViewController () <GMSAutocompleteViewControllerDelegate>
@end

@implementation AutocompletePushViewController {
  UIButton *_showAutocompleteWidgetButton;
}

+ (NSString *)demoTitle {
  return NSLocalizedString(
      @"Demo.Title.Autocomplete.Push",
      @"Title of the pushed autocomplete demo for display in a list or nav header");
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  // Configure the UI. Tell our superclass we want a button and a result view below that.
  _showAutocompleteWidgetButton =
      [self createShowAutocompleteButton:@selector(showAutocompleteWidgetButtonTapped)];
}

#pragma mark - Creation of |GMSAutocompleteViewController| instance.

- (GMSAutocompleteViewController *)autocompleteViewControllerInstance {
  GMSAutocompleteViewController *autocompleteViewController =
      [[GMSAutocompleteViewController alloc] init];
  autocompleteViewController.delegate = self;
  autocompleteViewController.autocompleteFilter = self.autocompleteFilter;
  autocompleteViewController.placeFields = self.placeFields;

  // Returns new GMSAutocompleteViewController instance.
  return autocompleteViewController;
}

#pragma mark - Actions

- (IBAction)showAutocompleteWidgetButtonTapped {
  // When the button is tapped just push a new autocomplete view controller onto the stack.
  [self.navigationController pushViewController:[self autocompleteViewControllerInstance]
                                       animated:YES];
  [_showAutocompleteWidgetButton setHidden:YES];
}

#pragma mark - GMSAutocompleteViewControllerDelegate

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
  // Dismiss the view controller and tell our superclass to populate the result view.
  [self.navigationController popToViewController:self animated:YES];
  [self autocompleteDidSelectPlace:place];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didFailAutocompleteWithError:(NSError *)error {
  // Dismiss the view controller and notify our superclass of the failure.
  [self.navigationController popToViewController:self animated:YES];
  [self autocompleteDidFail:error];
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
  // Dismiss the controller and show a message that it was canceled.
  [self.navigationController popToViewController:self animated:YES];
  [self autocompleteDidCancel];
}

- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
