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

#import "GooglePlacesDemos/DemoAppDelegate.h"

#import <GooglePlaces/GooglePlaces.h>
#import "GooglePlacesDemos/DemoData.h"
#import "GooglePlacesDemos/DemoListViewController.h"
#import "GooglePlacesDemos/SDKDemoAPIKey.h"

@implementation DemoAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSLog(@"Build version: %s", __VERSION__);

  // Do a quick check to see if you've provided an API key, in a real app you wouldn't need this but
  // for the demo it means we can provide a better error message.
  if (!kAPIKey.length) {
    // Blow up if APIKeys have not yet been set.
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *format = @"Configure APIKeys inside SDKDemoAPIKey.h for your  bundle `%@`, see "
                       @"README.GooglePlacesDemos for more information";
    @throw [NSException exceptionWithName:@"DemoAppDelegate"
                                   reason:[NSString stringWithFormat:format, bundleId]
                                 userInfo:nil];
  }

  // Provide the Places SDK with your API key.
  [GMSPlacesClient provideAPIKey:kAPIKey];

  // Log the required open source licenses! Yes, just NSLog-ing them is not enough but is good for
  // a demo.
  NSLog(@"Google Places open source licenses:\n%@", [GMSPlacesClient openSourceLicenseInfo]);

  // Manually create a window. If you are using a storyboard in your own app you can ignore the rest
  // of this method.
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  // Create our view controller with the list of demos.
  DemoData *demoData = [[DemoData alloc] init];
  DemoListViewController *masterViewController =
      [[DemoListViewController alloc] initWithDemoData:demoData];
  UINavigationController *masterNavigationController =
      [[UINavigationController alloc] initWithRootViewController:masterViewController];
  self.window.rootViewController = masterNavigationController;

  [self.window makeKeyAndVisible];

  return YES;
}

@end
