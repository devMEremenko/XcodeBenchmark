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

#import "GoogleMapsDemos/SampleListViewController.h"

#import "GoogleMapsDemos/Samples/Samples.h"
#import <GoogleMaps/GoogleMaps.h>


typedef NSMutableArray<NSArray<NSDictionary<NSString *, NSObject *> *> *> DemoSamplesArray;

@implementation SampleListViewController {
  NSArray<NSArray<NSDictionary<NSString *, id> *> *> *_demos;
  NSArray<NSArray<NSDictionary<NSString *, id> *> *> *_filteredDemos;
  NSArray<NSString *> *_demoSections;
  NSArray<NSString *> *_filteredDemoSections;
  CLLocationManager *_locationManager;
  BOOL _shouldCollapseDetailViewController;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _shouldCollapseDetailViewController = YES;
  self.title = NSLocalizedString(@"Maps SDK Demos", @"Maps SDK Demos");
  self.title = [NSString stringWithFormat:@"%@: %@", self.title, [GMSServices SDKLongVersion]];

  self.tableView.autoresizingMask =
      UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.tableView.accessibilityIdentifier = @"SamplesTableView";

  _demoSections = [Samples loadSections];
  _demos = [Samples loadDemos];

  _filteredDemos = _demos.copy;
  _filteredDemoSections = _demoSections.copy;

  UISearchController *searchController =
      [[UISearchController alloc] initWithSearchResultsController:nil];
  searchController.searchResultsUpdater = self;
  searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.navigationItem.searchController = searchController;
}

#pragma mark - UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return _filteredDemoSections.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 35.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return _filteredDemoSections[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray<NSDictionary<NSString *, id> *> *demosInSection = _filteredDemos[section];
  return demosInSection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:cellIdentifier];
  }

  cell.accessoryType = self.splitViewController.collapsed
                           ? UITableViewCellAccessoryDisclosureIndicator
                           : UITableViewCellAccessoryNone;

  NSDictionary<NSString *, id> *demo = [self demoAtIndexPath:indexPath];
  cell.textLabel.text = [demo objectForKey:@"title"];
  cell.detailTextLabel.text = [demo objectForKey:@"description"];
  cell.accessibilityLabel = [demo objectForKey:@"title"];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  _shouldCollapseDetailViewController = NO;
  NSDictionary<NSString *, id> *demo = [self demoAtIndexPath:indexPath];
  [self loadDemo:demo];
}

#pragma mark - Private methods

- (void)loadDemo:(NSDictionary<NSString *, id> *)demo {
  UIViewController *controller = [[[demo objectForKey:@"controller"] alloc] init];

  if (controller != nil) {
    controller.title = [demo objectForKey:@"title"];

    UINavigationController *navController =
        [[UINavigationController alloc] initWithRootViewController:controller];
    navController.navigationBar.translucent = NO;
    [self showDetailViewController:navController sender:nil];

    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    controller.navigationItem.leftItemsSupplementBackButton = YES;
  }
}

- (NSDictionary<NSString *, id> *)demoAtIndexPath:(NSIndexPath *)indexPath {
  return _filteredDemos[indexPath.section][indexPath.row];
}

#pragma mark - UISplitViewControllerDelegate methods

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:
    (UISplitViewController *)splitViewController {
  [self.tableView reloadData];
  return nil;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:
    (UISplitViewController *)splitViewController {
  [self.tableView reloadData];
  return nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController
    collapseSecondaryViewController:(UIViewController *)secondaryViewController
          ontoPrimaryViewController:(UIViewController *)primaryViewController {
  return _shouldCollapseDetailViewController;
}

#pragma mark - UISearchResultsUpdating methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
  NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
  NSString *text = searchController.searchBar.text;
  NSString *filterString = [text stringByTrimmingCharactersInSet:whitespaceCharacterSet];

  if ([filterString length] != 0) {
    NSPredicate *predicate = [NSPredicate
        predicateWithFormat:
            @"title CONTAINS[cd] %@ OR className CONTAINS[cd] %@ OR description CONTAINS[cd] %@",
            filterString, filterString, filterString];

    NSMutableArray<NSArray<NSDictionary<NSString *, id> *> *> *filteredDemos =
        [NSMutableArray array];
    NSMutableArray<NSString *> *filteredDemoSections = [NSMutableArray array];

    [_demos enumerateObjectsUsingBlock:^(id demosInSection, NSUInteger index, BOOL *stop) {
      NSArray<NSDictionary<NSString *, id> *> *filteredDemo =
          [demosInSection filteredArrayUsingPredicate:predicate];
      if ([filteredDemo count] != 0) {
        [filteredDemos addObject:filteredDemo];
        [filteredDemoSections addObject:_demoSections[index]];
      }
    }];

    _filteredDemos = filteredDemos.copy;
    _filteredDemoSections = filteredDemoSections.copy;

  } else {
    _filteredDemos = _demos.copy;
    _filteredDemoSections = _demoSections.copy;
  }

  [self.tableView reloadData];
}

@end
