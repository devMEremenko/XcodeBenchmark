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

#import <GooglePlaces/GooglePlaces.h>
#import "GooglePlacesDemos/Support/BaseDemoViewController.h"

/**
 * All other autocomplete demo classes inherit from this class. This class optionally adds a button
 * to present the autocomplete widget, and displays the results when these are selected.
 */
@interface AutocompleteBaseViewController : BaseDemoViewController

/** Filter to apply to autocomplete suggestions (can be nil). */
@property(nonatomic, strong) GMSAutocompleteFilter *autocompleteFilter;

/**
 * The |GMSPlaceField| for specifying explicit place details to be requested for the |GMSPlace|
 * result.
 */
@property(nonatomic, assign) GMSPlaceField placeFields;

/**
 * Build a UIButton to display the autocomplete widget and add it to the UI. This should be called
 * only if the demo requires such a button, e.g. demos for modal presentation of widgets would use
 * this, while a UITextField demo would not.
 *
 * @param selector The selector to send to self when the button is tapped.
 *
 * @return The UIButton which was added to the UI.
 */
- (UIButton *)createShowAutocompleteButton:(SEL)selector;

- (void)autocompleteDidSelectPlace:(GMSPlace *)place;
- (void)autocompleteDidFail:(NSError *)error;
- (void)autocompleteDidCancel;
- (void)showCustomMessageInResultPane:(NSString *)message;
- (void)resetViews;

@end
