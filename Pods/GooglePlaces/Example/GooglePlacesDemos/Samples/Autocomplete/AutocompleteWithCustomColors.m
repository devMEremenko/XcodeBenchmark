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

#import "GooglePlacesDemos/Samples/Autocomplete/AutocompleteWithCustomColors.h"

#import <GooglePlaces/GooglePlaces.h>

/**
 * Simple subclass of GMSAutocompleteViewController solely for the purpose of localising appearance
 * proxy changes to this part of the demo app.
 */
@interface GMSStyledAutocompleteViewController : GMSAutocompleteViewController
@end

@implementation GMSStyledAutocompleteViewController
@end

@interface AutocompleteWithCustomColors () <GMSAutocompleteViewControllerDelegate>
@end

@implementation AutocompleteWithCustomColors {
  NSMutableArray<UIButton *> *_themeButtons;
}

+ (NSString *)demoTitle {
  return NSLocalizedString(
      @"Demo.Title.Autocomplete.Styling",
      @"Title of the Styling autocomplete demo for display in a list or nav header");
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  NSString *titleYellowAndBrown =
      NSLocalizedString(@"Demo.Content.Autocomplete.Styling.Colors.YellowAndBrown",
                        @"Button title for the 'Yellow and Brown' styled autocomplete widget.");
  NSString *titleWhiteOnBlack =
      NSLocalizedString(@"Demo.Content.Autocomplete.Styling.Colors.WhiteOnBlack",
                        @"Button title for the 'WhiteOnBlack' styled autocomplete widget.");
  NSString *titleBlueColors =
      NSLocalizedString(@"Demo.Content.Autocomplete.Styling.Colors.BlueColors",
                        @"Button title for the 'BlueColors' styled autocomplete widget.");
  NSString *titleHotDogStand =
      NSLocalizedString(@"Demo.Content.Autocomplete.Styling.Colors.HotDogStand",
                        @"Button title for the 'Hot Dog Stand' styled autocomplete widget.");

  UIButton *brownThemeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [brownThemeButton setTitle:titleYellowAndBrown forState:UIControlStateNormal];
  [brownThemeButton addTarget:self
                       action:@selector(openBrownTheme:)
             forControlEvents:UIControlEventTouchUpInside];
  brownThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:brownThemeButton];
  [NSLayoutConstraint constraintWithItem:brownThemeButton
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.topLayoutGuide
                               attribute:NSLayoutAttributeBottom
                              multiplier:1
                                constant:8]
      .active = YES;
  [NSLayoutConstraint constraintWithItem:brownThemeButton
                               attribute:NSLayoutAttributeCenterX
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                               attribute:NSLayoutAttributeCenterX
                              multiplier:1
                                constant:0]
      .active = YES;

  UIButton *blackThemeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [blackThemeButton setTitle:titleWhiteOnBlack forState:UIControlStateNormal];
  [blackThemeButton addTarget:self
                       action:@selector(openBlackTheme:)
             forControlEvents:UIControlEventTouchUpInside];
  blackThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:blackThemeButton];
  [NSLayoutConstraint constraintWithItem:blackThemeButton
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:brownThemeButton
                               attribute:NSLayoutAttributeBottom
                              multiplier:1
                                constant:8]
      .active = YES;
  [NSLayoutConstraint constraintWithItem:blackThemeButton
                               attribute:NSLayoutAttributeCenterX
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                               attribute:NSLayoutAttributeCenterX
                              multiplier:1
                                constant:0]
      .active = YES;

  UIButton *blueThemeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [blueThemeButton setTitle:titleBlueColors forState:UIControlStateNormal];
  [blueThemeButton addTarget:self
                      action:@selector(openBlueTheme:)
            forControlEvents:UIControlEventTouchUpInside];
  blueThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:blueThemeButton];
  [NSLayoutConstraint constraintWithItem:blueThemeButton
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:blackThemeButton
                               attribute:NSLayoutAttributeBottom
                              multiplier:1
                                constant:8]
      .active = YES;
  [NSLayoutConstraint constraintWithItem:blueThemeButton
                               attribute:NSLayoutAttributeCenterX
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                               attribute:NSLayoutAttributeCenterX
                              multiplier:1
                                constant:0]
      .active = YES;

  UIButton *hotDogThemeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [hotDogThemeButton setTitle:titleHotDogStand forState:UIControlStateNormal];
  [hotDogThemeButton addTarget:self
                        action:@selector(openHotDogTheme:)
              forControlEvents:UIControlEventTouchUpInside];
  hotDogThemeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:hotDogThemeButton];
  [NSLayoutConstraint constraintWithItem:hotDogThemeButton
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:blueThemeButton
                               attribute:NSLayoutAttributeBottom
                              multiplier:1
                                constant:8]
      .active = YES;
  [NSLayoutConstraint constraintWithItem:hotDogThemeButton
                               attribute:NSLayoutAttributeCenterX
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                               attribute:NSLayoutAttributeCenterX
                              multiplier:1
                                constant:0]
      .active = YES;

  self.definesPresentationContext = YES;

  // Store the theme buttons into array.
  _themeButtons = [NSMutableArray array];
  [_themeButtons addObject:brownThemeButton];
  [_themeButtons addObject:blackThemeButton];
  [_themeButtons addObject:blueThemeButton];
  [_themeButtons addObject:hotDogThemeButton];
}

- (void)openBrownTheme:(UIButton *)button {
  UIColor *backgroundColor =
      [UIColor colorWithRed:215.0f / 255.0f green:204.0f / 255.0f blue:200.0f / 255.0f alpha:1.0f];
  UIColor *selectedTableCellBackgroundColor =
      [UIColor colorWithRed:236.0f / 255.0f green:225.0f / 255.0f blue:220.0f / 255.0f alpha:1.0f];
  UIColor *darkBackgroundColor =
      [UIColor colorWithRed:93.0f / 255.0f green:64.0f / 255.0f blue:55.0f / 255.0f alpha:1.0f];
  UIColor *primaryTextColor = [UIColor colorWithWhite:0.33f alpha:1.0f];

  UIColor *highlightColor =
      [UIColor colorWithRed:255.0f / 255.0f green:235.0f / 255.0f blue:0.0f / 255.0f alpha:1.0f];
  UIColor *secondaryColor = [UIColor colorWithWhite:114.0f / 255.0f alpha:1.0f];
  UIColor *tintColor =
      [UIColor colorWithRed:219 / 255.0f green:207 / 255.0f blue:28 / 255.0f alpha:1.0f];
  UIColor *searchBarTintColor = [UIColor yellowColor];
  UIColor *separatorColor = [UIColor colorWithWhite:182.0f / 255.0f alpha:1.0f];

  [self presentAutocompleteControllerWithBackgroundColor:backgroundColor
                        selectedTableCellBackgroundColor:selectedTableCellBackgroundColor
                                     darkBackgroundColor:darkBackgroundColor
                                        primaryTextColor:primaryTextColor
                                          highlightColor:highlightColor
                                          secondaryColor:secondaryColor
                                               tintColor:tintColor
                                      searchBarTintColor:searchBarTintColor
                                          separatorColor:separatorColor];
}

- (void)openBlueTheme:(UIButton *)button {
  UIColor *backgroundColor =
      [UIColor colorWithRed:225.0f / 255.0f green:241.0f / 255.0f blue:252.0f / 255.0f alpha:1.0f];
  UIColor *selectedTableCellBackgroundColor =
      [UIColor colorWithRed:213.0f / 255.0f green:219.0f / 255.0f blue:230.0f / 255.0f alpha:1.0f];
  UIColor *darkBackgroundColor =
      [UIColor colorWithRed:187.0f / 255.0f green:222.0f / 255.0f blue:248.0f / 255.0f alpha:1.0f];
  UIColor *primaryTextColor = [UIColor colorWithWhite:0.5f alpha:1.0f];
  UIColor *highlightColor =
      [UIColor colorWithRed:76.0f / 255.0f green:175.0f / 255.0f blue:248.0f / 255.0f alpha:1.0f];
  UIColor *secondaryColor = [UIColor colorWithWhite:0.5f alpha:0.65f];
  UIColor *tintColor =
      [UIColor colorWithRed:0 / 255.0f green:142 / 255.0f blue:248.0f / 255.0f alpha:1.0f];
  UIColor *searchBarTintColor = tintColor;
  UIColor *separatorColor = [UIColor colorWithWhite:0.5f alpha:0.65f];

  [self presentAutocompleteControllerWithBackgroundColor:backgroundColor
                        selectedTableCellBackgroundColor:selectedTableCellBackgroundColor
                                     darkBackgroundColor:darkBackgroundColor
                                        primaryTextColor:primaryTextColor
                                          highlightColor:highlightColor
                                          secondaryColor:secondaryColor
                                               tintColor:tintColor
                                      searchBarTintColor:searchBarTintColor
                                          separatorColor:separatorColor];
}

- (void)openBlackTheme:(UIButton *)button {
  UIColor *backgroundColor = [UIColor colorWithWhite:0.25f alpha:1.0f];
  UIColor *selectedTableCellBackgroundColor = [UIColor colorWithWhite:0.35f alpha:1.0f];
  UIColor *darkBackgroundColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
  UIColor *primaryTextColor = [UIColor whiteColor];
  UIColor *highlightColor = [UIColor colorWithRed:0.75f green:1.0f blue:0.75f alpha:1.0f];
  UIColor *secondaryColor = [UIColor colorWithWhite:1.0f alpha:0.5f];
  UIColor *tintColor = [UIColor whiteColor];
  UIColor *searchBarTintColor = tintColor;
  UIColor *separatorColor = [UIColor colorWithRed:0.5f green:0.75f blue:0.5f alpha:0.30f];

  [self presentAutocompleteControllerWithBackgroundColor:backgroundColor
                        selectedTableCellBackgroundColor:selectedTableCellBackgroundColor
                                     darkBackgroundColor:darkBackgroundColor
                                        primaryTextColor:primaryTextColor
                                          highlightColor:highlightColor
                                          secondaryColor:secondaryColor
                                               tintColor:tintColor
                                      searchBarTintColor:searchBarTintColor
                                          separatorColor:separatorColor];
}

- (void)openHotDogTheme:(UIButton *)button {
  UIColor *backgroundColor = [UIColor yellowColor];
  UIColor *selectedTableCellBackgroundColor = [UIColor whiteColor];
  UIColor *darkBackgroundColor = [UIColor redColor];
  UIColor *primaryTextColor = [UIColor blackColor];
  UIColor *highlightColor = [UIColor redColor];
  UIColor *secondaryColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
  UIColor *tintColor = [UIColor redColor];
  UIColor *searchBarTintColor = [UIColor whiteColor];
  UIColor *separatorColor = [UIColor redColor];

  [self presentAutocompleteControllerWithBackgroundColor:backgroundColor
                        selectedTableCellBackgroundColor:selectedTableCellBackgroundColor
                                     darkBackgroundColor:darkBackgroundColor
                                        primaryTextColor:primaryTextColor
                                          highlightColor:highlightColor
                                          secondaryColor:secondaryColor
                                               tintColor:tintColor
                                      searchBarTintColor:searchBarTintColor
                                          separatorColor:separatorColor];
}

- (void)presentAutocompleteControllerWithBackgroundColor:(UIColor *)backgroundColor
                        selectedTableCellBackgroundColor:(UIColor *)selectedTableCellBackgroundColor
                                     darkBackgroundColor:(UIColor *)darkBackgroundColor
                                        primaryTextColor:(UIColor *)primaryTextColor
                                          highlightColor:(UIColor *)highlightColor
                                          secondaryColor:(UIColor *)secondaryColor
                                               tintColor:(UIColor *)tintColor
                                      searchBarTintColor:(UIColor *)searchBarTintColor
                                          separatorColor:(UIColor *)separatorColor {
  // Use UIAppearance proxies to change the appearance of UI controls in
  // GMSAutocompleteViewController. Here we use appearanceWhenContainedInInstancesOfClasses to
  // localise changes to just this part of the Demo app. This will generally not be necessary in a
  // real application as you will probably want the same theme to apply to all elements in your app.
  UIActivityIndicatorView *appearance = [UIActivityIndicatorView
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]];
  [appearance setColor:primaryTextColor];

  [[UINavigationBar
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]]
      setBarTintColor:darkBackgroundColor];
  [[UINavigationBar
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]]
      setTintColor:searchBarTintColor];

  // Color of typed text in search bar.
  NSDictionary *searchBarTextAttributes = @{
    NSForegroundColorAttributeName : searchBarTintColor,
    NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]
  };
  [[UITextField
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]]
      setDefaultTextAttributes:searchBarTextAttributes];

  // Color of the "Search" placeholder text in search bar. For this example, we'll make it the same
  // as the bar tint color but with added transparency.
  CGFloat increasedAlpha = CGColorGetAlpha(searchBarTintColor.CGColor) * 0.75f;
  UIColor *placeHolderColor = [searchBarTintColor colorWithAlphaComponent:increasedAlpha];

  NSDictionary *placeholderAttributes = @{
    NSForegroundColorAttributeName : placeHolderColor,
    NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]
  };
  NSAttributedString *attributedPlaceholder =
      [[NSAttributedString alloc] initWithString:@"Search" attributes:placeholderAttributes];

  [[UITextField
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]]
      setAttributedPlaceholder:attributedPlaceholder];

  // Change the background color of selected table cells.
  UIView *selectedBackgroundView = [[UIView alloc] init];
  selectedBackgroundView.backgroundColor = selectedTableCellBackgroundColor;
  id tableCellAppearance = [UITableViewCell
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]];
  [tableCellAppearance setSelectedBackgroundView:selectedBackgroundView];

  // Depending on the navigation bar background color, it might also be necessary to customise the
  // icons displayed in the search bar to something other than the default. The
  // setupSearchBarCustomIcons method contains example code to do this.

  GMSAutocompleteViewController *acController = [[GMSStyledAutocompleteViewController alloc] init];
  acController.delegate = self;
  acController.autocompleteFilter = self.autocompleteFilter;
  acController.placeFields = self.placeFields;
  acController.tableCellBackgroundColor = backgroundColor;
  acController.tableCellSeparatorColor = separatorColor;
  acController.primaryTextColor = primaryTextColor;
  acController.primaryTextHighlightColor = highlightColor;
  acController.secondaryTextColor = secondaryColor;
  acController.tintColor = tintColor;

  [self presentViewController:acController animated:YES completion:nil];
  // Hide theme buttons.
  for (UIButton *button in _themeButtons) {
    [button setHidden:YES];
  }
}

/*
 * This method shows how to replace the "search" and "clear text" icons in the search bar with
 * custom icons in the case where the default gray icons don't match a custom background.
 */
- (void)setupSearchBarCustomIcons {
  id searchBarAppearanceProxy = [UISearchBar
      appearanceWhenContainedInInstancesOfClasses:@ [[GMSStyledAutocompleteViewController class]]];
  [searchBarAppearanceProxy setImage:[UIImage imageNamed:@"custom_clear_x_high"]
                    forSearchBarIcon:UISearchBarIconClear
                               state:UIControlStateHighlighted];
  [searchBarAppearanceProxy setImage:[UIImage imageNamed:@"custom_clear_x"]
                    forSearchBarIcon:UISearchBarIconClear
                               state:UIControlStateNormal];
  [searchBarAppearanceProxy setImage:[UIImage imageNamed:@"custom_search"]
                    forSearchBarIcon:UISearchBarIconSearch
                               state:UIControlStateNormal];
}

#pragma mark - GMSAutocompleteViewControllerDelegate

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didAutocompleteWithPlace:(GMSPlace *)place {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self autocompleteDidSelectPlace:place];
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
    didFailAutocompleteWithError:(NSError *)error {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self autocompleteDidFail:error];
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self autocompleteDidCancel];
}

- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
