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

#import "GooglePlacesDemos/DemoListViewController.h"

#import <GooglePlaces/GooglePlaces.h>


// The cell reuse identifier we are going to use.
static NSString *gOverrideVersion = nil;
static NSString *const kCellIdentifier = @"DemoCellIdentifier";
static const CGFloat kSelectionHeight = 40;
static const CGFloat kSelectionSwitchWidth = 50;
static const CGFloat kEdgeBuffer = 8;

@implementation DemoListViewController {
  UIViewController *_editSelectionsViewController;
  NSMutableDictionary<NSString *, UISwitch *> *_autocompleteFiltersSelectionMap;
  NSMutableDictionary<NSNumber *, UISwitch *> *_placeFieldsSelectionMap;
  NSMutableDictionary<NSString *, UISwitch *> *_restrictionBoundsMap;
  CGFloat _nextSelectionYPos;
  DemoData *_demoData;
}

- (instancetype)initWithDemoData:(DemoData *)demoData {
  if ((self = [self init])) {
    _demoData = demoData;
    _autocompleteFiltersSelectionMap = [NSMutableDictionary dictionary];
    _placeFieldsSelectionMap = [NSMutableDictionary dictionary];
    _restrictionBoundsMap = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  // Set up the title for view to be displayed.
  self.title = [DemoListViewController titleText];
  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  // Clear the title to make room for next view to share the header space in splitscreen view.
  self.title = nil;
  [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UINavigationBar *navBar = self.navigationController.navigationBar;

  UINavigationBarAppearance *navBarAppearance = [[UINavigationBarAppearance alloc] init];
  [navBarAppearance configureWithOpaqueBackground];
  navBarAppearance.backgroundColor = [UIColor systemBackgroundColor];
  [navBarAppearance
      setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor labelColor]}];

  navBar.standardAppearance = navBarAppearance;
  navBar.scrollEdgeAppearance = navBarAppearance;

  [self setUpEditSelectionsUI];

  // Add button to the header to edit the place field selections.
  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                    target:self
                                                    action:@selector(beginEditSelections)];

  // Register a plain old UITableViewCell as this will be sufficient for our list.
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(orientationChanged:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:[UIDevice currentDevice]];
}

/**
 * Private method which is called when a demo is selected. Constructs the demo view controller and
 * displays it.
 *
 * @param demo The demo to show.
 */
- (void)showDemo:(Demo *)demo {
  CLLocationCoordinate2D northEast = kCLLocationCoordinate2DInvalid;
  CLLocationCoordinate2D southWest = kCLLocationCoordinate2DInvalid;
  GMSAutocompleteFilter *autocompleteFilter = [self autocompleteFilter];

  // Check for restriction bounds settings.
  if (_restrictionBoundsMap[@"Kansas"].on) {
    northEast = CLLocationCoordinate2DMake(39.0, -95.0);
    southWest = CLLocationCoordinate2DMake(37.5, -100.0);
    autocompleteFilter.origin = [[CLLocation alloc] initWithLatitude:northEast.latitude
                                                           longitude:northEast.longitude];
    autocompleteFilter.locationRestriction =
        GMSPlaceRectangularLocationOption(northEast, southWest);
  } else if (_restrictionBoundsMap[@"Canada"].on) {
    northEast = CLLocationCoordinate2DMake(70.0, -60.0);
    southWest = CLLocationCoordinate2DMake(50.0, -140.0);
    autocompleteFilter.origin = [[CLLocation alloc] initWithLatitude:northEast.latitude
                                                           longitude:northEast.longitude];
    autocompleteFilter.locationRestriction =
        GMSPlaceRectangularLocationOption(northEast, southWest);
  }

  // Create view controller with the autocomplete filters, bounds and selected place fields.
  UIViewController *viewController =
      [demo createViewControllerWithAutocompleteFilter:autocompleteFilter
                                           placeFields:[self selectedPlaceFields]];

  [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Edit Autocomplete Filters and Place Fields selections UI

- (void)setUpEditSelectionsUI {
  // Initialize the place fields selection UI.
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
  scrollView.backgroundColor = [UIColor systemBackgroundColor];

  // Add heading for the autocomplete type filters.
  _nextSelectionYPos = [UIApplication sharedApplication].statusBarFrame.size.height;
  [scrollView addSubview:[self headerLabelForTitle:@"Autocomplete Filters"]];

  // Set up the individual autocomplete type filters we can limit the results to. Add a heading for
  // the place fields that we can request.
  _nextSelectionYPos += kSelectionHeight;
  [scrollView addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeRestaurant]];
  [scrollView addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeAirport]];
  [scrollView addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeGeocode]];
  [scrollView
      addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeEstablishment]];
  [scrollView
      addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeCollectionAddress]];
  [scrollView
      addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeCollectionRegion]];
  [scrollView
      addSubview:[self selectionButtonForAutocompleteFilterType:kGMSPlaceTypeCollectionCity]];

  // Add heading for the autocomplete restriction bounds.
  [scrollView addSubview:[self headerLabelForTitle:@"Autocomplete Restriction Bounds"]];

  // Set up the restriction bounds for testing purposes.
  _nextSelectionYPos += kSelectionHeight;
  [scrollView addSubview:[self selectionButtonForRestrictionBoundsArea:@"Canada"]];

  _nextSelectionYPos += kSelectionHeight;
  [scrollView addSubview:[self selectionButtonForRestrictionBoundsArea:@"Kansas"]];

  // Add heading for the place fields that we can request.
  _nextSelectionYPos += kSelectionHeight;
  [scrollView addSubview:[self headerLabelForTitle:@"Place Fields"]];

  // Set up the individual place fields that we can request.
  _nextSelectionYPos += kSelectionHeight;
  for (uint64_t placeField = GMSPlaceFieldName; placeField <= GMSPlaceFieldIconBackgroundColor;
       placeField <<= 1) {
    [scrollView addSubview:[self selectionButtonForPlaceField:(GMSPlaceField)placeField]];
  }

  // Add the close button to dismiss the selection UI.
  UIButton *close =
      [[UIButton alloc] initWithFrame:CGRectMake(0, _nextSelectionYPos, self.view.frame.size.width,
                                                 kSelectionHeight)];
  close.backgroundColor = [UIColor systemBlueColor];
  [close setTitle:@"Close" forState:UIControlStateNormal];
  [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [close addTarget:self
                action:@selector(endEditSelections:)
      forControlEvents:UIControlEventTouchUpInside];
  [scrollView addSubview:close];

  // Set the content size for the scroll view after we determine the height of all the contents.
  scrollView.contentSize = CGSizeMake(scrollView.frame.size.width,
                                      close.frame.origin.y + close.frame.size.height + kEdgeBuffer);

  // Initialize the edit selections view controller.
  _editSelectionsViewController = [[UIViewController alloc] init];
  _editSelectionsViewController.view = scrollView;
}

- (void)updateFrameForSelectionViews:(UIView *)view {
  CGFloat horizontalInset = [self horizontalInset];
  view.frame =
      CGRectMake(horizontalInset, view.frame.origin.y,
                 self.view.frame.size.width - (2 * horizontalInset), view.frame.size.height);
  for (UIView *subView in view.subviews) {
    if ([subView isKindOfClass:[UISwitch class]]) {
      subView.frame =
          CGRectMake(view.frame.size.width - kSelectionSwitchWidth, subView.frame.origin.y,
                     subView.frame.size.width, subView.frame.size.height);
    }
  }
}

- (UILabel *)headerLabelForTitle:(NSString *)title {
  UILabel *headerLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(0, _nextSelectionYPos, self.view.frame.size.width,
                                                kSelectionHeight)];
  headerLabel.backgroundColor = [UIColor lightGrayColor];
  headerLabel.text = title;
  headerLabel.textAlignment = NSTextAlignmentCenter;
  headerLabel.textColor = [UIColor whiteColor];
  headerLabel.userInteractionEnabled = NO;
  return headerLabel;
}

- (UIButton *)selectionButtonForTitle:(NSString *)title {
  UIButton *selectionButton =
      [[UIButton alloc] initWithFrame:CGRectMake(0, _nextSelectionYPos, self.view.frame.size.width,
                                                 kSelectionHeight)];
  UISwitch *selectionSwitch = [[UISwitch alloc]
      initWithFrame:CGRectMake(selectionButton.frame.size.width - kSelectionSwitchWidth,
                               kEdgeBuffer / 2, kSelectionSwitchWidth, kSelectionHeight)];
  selectionSwitch.userInteractionEnabled = NO;
  [selectionButton addTarget:self
                      action:@selector(selectionButtonTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  [selectionButton setBackgroundColor:[UIColor systemBackgroundColor]];
  [selectionButton setTitle:title forState:UIControlStateNormal];
  [selectionButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
  selectionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
  [selectionButton addSubview:selectionSwitch];
  return selectionButton;
}

- (UIButton *)selectionButtonForPlaceField:(GMSPlaceField)placeField {
  NSDictionary<NSNumber *, NSString *> *fieldsMapping = @{
    @(GMSPlaceFieldName) : @"Name",
    @(GMSPlaceFieldPlaceID) : @"Place ID",
    @(GMSPlaceFieldPlusCode) : @"Plus Code",
    @(GMSPlaceFieldCoordinate) : @"Coordinate",
    @(GMSPlaceFieldOpeningHours) : @"Opening Hours",
    @(GMSPlaceFieldPhoneNumber) : @"Phone Number",
    @(GMSPlaceFieldFormattedAddress) : @"Formatted Address",
    @(GMSPlaceFieldRating) : @"Rating",
    @(GMSPlaceFieldUserRatingsTotal) : @"User Ratings Total",
    @(GMSPlaceFieldPriceLevel) : @"Price Level",
    @(GMSPlaceFieldTypes) : @"Types",
    @(GMSPlaceFieldWebsite) : @"Website",
    @(GMSPlaceFieldViewport) : @"Viewport",
    @(GMSPlaceFieldAddressComponents) : @"Address Components",
    @(GMSPlaceFieldPhotos) : @"Photos",
    @(GMSPlaceFieldUTCOffsetMinutes) : @"UTC Offset Minutes",
    @(GMSPlaceFieldBusinessStatus) : @"Business Status",
    @(GMSPlaceFieldIconImageURL) : @"Icon Image URL",
    @(GMSPlaceFieldIconBackgroundColor) : @"Icon Background Color",
  };
  UIButton *selectionButton = [self selectionButtonForTitle:fieldsMapping[@(placeField)]];
  UISwitch *selectionSwitch = [self switchFromButton:selectionButton];
  [selectionSwitch setOn:YES];
  _placeFieldsSelectionMap[@(placeField)] = selectionSwitch;
  _nextSelectionYPos += selectionButton.frame.size.height;
  return selectionButton;
}

- (UIButton *)selectionButtonForAutocompleteFilterType:(NSString *)autocompleteFilter {
  UIButton *selectionButton = [self selectionButtonForTitle:autocompleteFilter];
  [selectionButton addTarget:self
                      action:@selector(disableOtherAutocompleteFilterExceptForTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  UISwitch *selectionSwitch = [self switchFromButton:selectionButton];
  [selectionSwitch setOn:NO];
  _autocompleteFiltersSelectionMap[autocompleteFilter] = selectionSwitch;
  _nextSelectionYPos += selectionButton.frame.size.height;
  return selectionButton;
}

- (UIButton *)selectionButtonForRestrictionBoundsArea:(NSString *)area {
  UIButton *selectionButton = [self selectionButtonForTitle:area];
  [selectionButton addTarget:self
                      action:@selector(disableOtherRestrictionBoundsExceptForTapped:)
            forControlEvents:UIControlEventTouchUpInside];
  _restrictionBoundsMap[area] = [self switchFromButton:selectionButton];
  [_restrictionBoundsMap[area] setOn:NO];
  return selectionButton;
}

- (UISwitch *)switchFromButton:(UIButton *)button {
  for (UIView *subView in button.subviews) {
    if ([subView isKindOfClass:[UISwitch class]]) {
      return (UISwitch *)subView;
    }
  }
  return nil;
}

- (void)selectionButtonTapped:(UIButton *)sender {
  UISwitch *selectionSwitch = [self switchFromButton:sender];
  [selectionSwitch setOn:selectionSwitch.on ? NO : YES animated:YES];
}

- (void)disableOtherAutocompleteFilterExceptForTapped:(UIButton *)sender {
  UISwitch *tappedSwitch = [self switchFromButton:sender];
  for (NSString *filterType in _autocompleteFiltersSelectionMap) {
    UISwitch *selectionSwitch = _autocompleteFiltersSelectionMap[filterType];
    if (selectionSwitch != tappedSwitch) {
      [selectionSwitch setOn:NO animated:YES];
    }
  }
}

- (void)disableOtherRestrictionBoundsExceptForTapped:(UIButton *)sender {
  UISwitch *tappedSwitch = [self switchFromButton:sender];
  for (NSString *key in [_restrictionBoundsMap allKeys]) {
    UISwitch *selectionSwitch = _restrictionBoundsMap[key];
    if (selectionSwitch != tappedSwitch) {
      [selectionSwitch setOn:NO animated:YES];
    }
  }
}

- (void)beginEditSelections {
  // Update the selection views to fit the current device frame and orientation.
  for (UIView *view in _editSelectionsViewController.view.subviews) {
    [self updateFrameForSelectionViews:view];
  }

  // Scroll the contents to the top before presenting the selection UI.
  UIScrollView *scrollView = (UIScrollView *)_editSelectionsViewController.view;
  [scrollView setContentOffset:CGPointZero animated:NO];

  // Default modalPresentationStyle reduces width of view on iPad, view needs to be full width
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    _editSelectionsViewController.modalPresentationStyle = UIModalPresentationFullScreen;
  }

  // Present the selection UI to edit which place fields to request.
  [self.navigationController presentViewController:_editSelectionsViewController
                                          animated:YES
                                        completion:nil];
}

- (void)endEditSelections:(UIButton *)sender {
  [_editSelectionsViewController dismissViewControllerAnimated:YES completion:nil];
}

- (GMSAutocompleteFilter *)autocompleteFilter {
  GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
  for (NSString *filterType in _autocompleteFiltersSelectionMap) {
    UISwitch *selectionSwitch = _autocompleteFiltersSelectionMap[filterType];
    if ([selectionSwitch isOn]) {
      filter.types = @[ filterType ];
      break;
    }
  }
  return filter;
}

- (GMSPlaceField)selectedPlaceFields {
  GMSPlaceField placeFields = 0;
  for (NSNumber *number in _placeFieldsSelectionMap) {
    UISwitch *selectionSwitch = _placeFieldsSelectionMap[number];
    if ([selectionSwitch isOn]) {
      placeFields |= [number integerValue];
    }
  }
  return placeFields;
}

- (CGFloat)horizontalInset {
  // Take into account the safe areas of the device screen and do not use that space.
  return MAX(self.view.safeAreaInsets.left, self.view.safeAreaInsets.right) + kEdgeBuffer;
}

#pragma mark - UITableViewDataSource/Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return _demoData.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _demoData.sections[section].demos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // Dequeue a table view cell to use.
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                                          forIndexPath:indexPath];

  // Grab the demo object.
  Demo *demo = _demoData.sections[indexPath.section].demos[indexPath.row];

  // Configure the demo title on the cell.
  cell.textLabel.text = demo.title;

  return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return _demoData.sections[section].title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Get the demo which was selected.
  Demo *demo = _demoData.sections[indexPath.section].demos[indexPath.row];
  [self showDemo:demo];
}

+ (NSString *)overrideVersion {
  return [[[NSProcessInfo processInfo] environment] objectForKey:@"PLACES_VERSION_NUMBER_OVERRIDE"];
}

+ (NSString *)titleText {
  NSString *titleFormat = NSLocalizedString(
      @"App.NameAndVersion", @"The name of the app to display in a navigation bar along with a "
                             @"placeholder for the SDK version number");
  return [NSString
      stringWithFormat:titleFormat, [self overrideVersion] ?: [GMSPlacesClient SDKLongVersion]];
}

#pragma mark - Handle Orientation Changes

- (void)orientationChanged:(NSNotification *)notification {
  // Dismiss the selections UI if currently active.
  if (_editSelectionsViewController.isViewLoaded && _editSelectionsViewController.view.window) {
    [self endEditSelections:nil];
  }
}

@end
