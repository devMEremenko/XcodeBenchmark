/*
 * Copyright 2019 Google LLC. All rights reserved.
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

#import "GooglePlacesDemos/Samples/FindPlaceLikelihoodListViewController.h"

#import <GooglePlaces/GooglePlaces.h>


static NSString *const kCellIdentifier = @"LikelihoodCellIdentifier";

#pragma mark - ButtonCoordinateView

@interface ButtonCoordinateView : UIView

// The button used to trigger the fetch likelihoods from coordinate action.
@property(nonatomic, strong) UIButton *button;

@end

@implementation ButtonCoordinateView {
}

- (instancetype)init {
  if (self = [super init]) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.layer.cornerRadius = 3;
  self.layer.masksToBounds = YES;
  self.layer.borderColor = [UIColor clearColor].CGColor;
  self.layer.borderWidth = 1;

  UIStackView *stackView = [[UIStackView alloc] init];
  stackView.axis = UILayoutConstraintAxisHorizontal;
  stackView.spacing = 15;
  stackView.layoutMargins = UIEdgeInsetsMake(5, 0, 5, 0);
  stackView.layoutMarginsRelativeArrangement = YES;
  [self addSubview:stackView];

  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:@"Retrieve location" forState:UIControlStateNormal];
  [stackView addArrangedSubview:button];
  _button = button;

  UIStackView *labelsStackView = [[UIStackView alloc] init];
  labelsStackView.axis = UILayoutConstraintAxisVertical;
  [stackView addArrangedSubview:labelsStackView];

  [stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [NSLayoutConstraint activateConstraints:@[
    [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [stackView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
  ]];
}

// Sets the title and target for the button.
- (void)fillWithButtonTitle:(NSString *)title
                     target:(id)target
                     action:(SEL)action
           forControlEvents:(UIControlEvents)controlEvents {
  [_button setTitle:title forState:UIControlStateNormal];
  [_button addTarget:target action:action forControlEvents:controlEvents];
}


@end

#pragma mark - FindPlaceLikelihoodListViewController

@interface FindPlaceLikelihoodListViewController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray<GMSPlaceLikelihood *> *placeLikelihoods;
@property(nonatomic, strong) UILabel *errorLabel;
@property(nonatomic, strong) ButtonCoordinateView *currentButtonCoordinateView;

@end

@implementation FindPlaceLikelihoodListViewController {
  CLLocationManager *_locationManager;
  GMSPlacesClient *_placesClient;
}

+ (NSString *)demoTitle {
  return @"Find Place Likelihoods";
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _placesClient = [GMSPlacesClient sharedClient];

  // Initializes the location manager to be used for current location.
  CLLocationManager *locationManager = [[CLLocationManager alloc] init];
  locationManager.delegate = self;
  _locationManager = locationManager;

  self.title = [NSString stringWithFormat:@"Find place likelihoods from location"];
  self.view.backgroundColor = [UIColor whiteColor];

  UIStackView *mainStackView = [[UIStackView alloc] init];
  mainStackView.axis = UILayoutConstraintAxisVertical;
  [self.view addSubview:mainStackView];

  // Adds the location input section.
  UIStackView *locationInputStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
  locationInputStackView.axis = UILayoutConstraintAxisVertical;
  locationInputStackView.layoutMargins = UIEdgeInsetsMake(20, 15, 0, 15);
  locationInputStackView.layoutMarginsRelativeArrangement = YES;
  locationInputStackView.distribution = UIStackViewDistributionFill;
  locationInputStackView.alignment = UIStackViewAlignmentFill;
  locationInputStackView.spacing = 10;
  [mainStackView addArrangedSubview:locationInputStackView];

  ButtonCoordinateView *currentView = [[ButtonCoordinateView alloc] init];
  [currentView fillWithButtonTitle:@"Find from current location"
                            target:self
                            action:@selector(onCurrentLocationTap)
                  forControlEvents:UIControlEventTouchUpInside];
  [locationInputStackView addArrangedSubview:currentView];
  _currentButtonCoordinateView = currentView;


  UILabel *errorLabel = [[UILabel alloc] init];
  errorLabel.textColor = [UIColor redColor];
  errorLabel.numberOfLines = 0;
  [locationInputStackView addArrangedSubview:errorLabel];
  _errorLabel = errorLabel;

  // Adds the likelihood list table.
  UITableView *tableView = [[UITableView alloc] init];
  [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
  tableView.delegate = self;
  tableView.dataSource = self;
  [mainStackView addArrangedSubview:tableView];
  _tableView = tableView;

  mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
  NSArray<NSLayoutConstraint *> *stackViewConstraints = @[
    [mainStackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [mainStackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [mainStackView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
    [mainStackView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor]
  ];
#if defined(__IPHONE_11_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
  if (@available(iOS 11.0, *)) {
    stackViewConstraints = @[
      [mainStackView.leadingAnchor
          constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
      [mainStackView.trailingAnchor
          constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
      [mainStackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [mainStackView.bottomAnchor
          constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ];
  }
#endif
  [NSLayoutConstraint activateConstraints:stackViewConstraints];

  [self onCurrentLocationTap];
}

#pragma mark - Button Handlers

// Requests location services authorization if needed, and starts updating location.
- (void)onCurrentLocationTap {
  if (![FindPlaceLikelihoodListViewController areLocationServicesEnabledAndAuthorized]) {
    [_locationManager requestWhenInUseAuthorization];

    return;
  }

  [_locationManager startUpdatingLocation];

  __block FindPlaceLikelihoodListViewController *weakSelf = self;
  GMSPlaceLikelihoodsCallback fetcherCallback =
      ^(NSArray<GMSPlaceLikelihood *> *_Nullable likelihoods, NSError *_Nullable error) {
        [weakSelf handleFindPlaceLikelihoodsResponse:likelihoods error:error];
      };

  [_placesClient findPlaceLikelihoodsFromCurrentLocationWithPlaceFields:GMSPlaceFieldAll
                                                               callback:fetcherCallback];
}


#pragma mark - CLLocationManagerDelegate

// Retries retrieving current location if user has granted location services permission.
- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
    // Retry current location fetch once user enables Location Services.
    [self onCurrentLocationTap];
  } else {
    _errorLabel.text = @"Please make sure location services are enabled.";
  }
}


#pragma mark - UITableViewDataSource/Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (_placeLikelihoods == nil) {
    return 0;
  }
  return _placeLikelihoods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                                          forIndexPath:indexPath];
  cell.textLabel.numberOfLines = 0;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  NSInteger row = indexPath.row;
  NSInteger likelihoodCount = _placeLikelihoods.count;
  if (likelihoodCount > 0 && row < likelihoodCount) {
    GMSPlaceLikelihood *likelihood = _placeLikelihoods[row];
    cell.textLabel.text = likelihood.place.name;
  }

  return cell;
}

#pragma mark - Helpers

// Checks if user has authorized location services required for retrieving device location.
+ (BOOL)areLocationServicesEnabledAndAuthorized {
  if (![CLLocationManager locationServicesEnabled]) {
    return NO;
  }

  CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
  return status == kCLAuthorizationStatusAuthorizedAlways ||
         status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (void)handleFindPlaceLikelihoodsResponse:(NSArray<GMSPlaceLikelihood *> *)likelihoods
                                     error:(NSError *)error {
  if (error != nil) {
    _errorLabel.text = @"There was an error fetching likelihoods.";
    return;
  }

  // Filters out Places that don't have a valid name.
  NSPredicate *predicate = [NSPredicate
      predicateWithBlock:^BOOL(GMSPlaceLikelihood *likelihood, NSDictionary<NSString *, id> *b) {
        return likelihood.place.name != nil && [likelihood.place.name length] > 0;
      }];
  _placeLikelihoods = [likelihoods filteredArrayUsingPredicate:predicate];
  _errorLabel.text = nil;
  [_tableView reloadData];
  [self resignFirstResponder];
}


@end
