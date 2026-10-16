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

#import "GoogleMapsDemos/MasterViewController.h"

#import "GoogleMapsDemos/Samples/Samples.h"
#import <GoogleMaps/GoogleMaps.h>


typedef NSMutableArray<NSArray<NSDictionary<NSString *, NSObject *> *> *> DemoSamplesArray;

@implementation MasterViewController {
  NSArray *_demos;
  NSArray *_demoSections;
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
}

#pragma mark - UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return _demoSections.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 35.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [_demoSections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSArray *demosInSection = [_demos objectAtIndex:section];
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

  NSDictionary *demo = [[_demos objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  cell.textLabel.text = [demo objectForKey:@"title"];
  cell.detailTextLabel.text = [demo objectForKey:@"description"];
  cell.accessibilityLabel = [demo objectForKey:@"title"];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  _shouldCollapseDetailViewController = NO;
  [self loadDemo:indexPath.section atIndex:indexPath.row];
}

#pragma mark - Private methods

- (void)loadDemo:(NSUInteger)section atIndex:(NSUInteger)index {
  NSDictionary *demo = [[_demos objectAtIndex:section] objectAtIndex:index];
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

@end
