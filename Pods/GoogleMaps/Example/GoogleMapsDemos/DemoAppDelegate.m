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

#import "GoogleMapsDemos/DemoAppDelegate.h"

#import "GoogleMapsDemos/MasterViewController.h"
#import "GoogleMapsDemos/SDKDemoAPIKey.h"
#import <GoogleMaps/GoogleMaps.h>

@implementation DemoAppDelegate {
  id _services;
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSLog(@"Build version: %s", __VERSION__);

  if (kAPIKey.length == 0) {
    // Blow up if APIKey has not yet been set.
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *format = @"Configure APIKey inside SDKDemoAPIKey.h for your "
                       @"bundle `%@`, see README.GoogleMapsDemos for more information";
    @throw [NSException exceptionWithName:@"DemoAppDelegate"
                                   reason:[NSString stringWithFormat:format, bundleId]
                                 userInfo:nil];
  }
  [GMSServices provideAPIKey:kAPIKey];
  _services = [GMSServices sharedServices];

  // Log the required open source licenses! Yes, just NSLog-ing them is not enough but is good for
  // a demo.
  NSLog(@"Open source licenses:\n%@", [GMSServices openSourceLicenseInfo]);

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  MasterViewController *master = [[MasterViewController alloc] init];

  UINavigationController *masterNavigationController =
      [[UINavigationController alloc] initWithRootViewController:master];

  UIViewController *empty = [[UIViewController alloc] init];
  UINavigationController *detailNavigationController =
      [[UINavigationController alloc] initWithRootViewController:empty];

  self.splitViewController = [[UISplitViewController alloc] init];
  self.splitViewController.delegate = master;
  self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
  self.splitViewController.viewControllers =
      @[ masterNavigationController, detailNavigationController ];

  empty.navigationItem.leftItemsSupplementBackButton = YES;
  empty.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;

  self.window.rootViewController = self.splitViewController;

  [self.window makeKeyAndVisible];
  return YES;
}

@end
