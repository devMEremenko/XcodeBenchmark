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

#import "GoogleMapsDemos/DemoSceneDelegate.h"
#import "GoogleMapsDemos/SDKDemoAPIKey.h"
#import <GoogleMaps/GoogleMaps.h>

@implementation DemoAppDelegate

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

  // Metal is the preferred renderer.
  [GMSServices setMetalRendererEnabled:YES];
  self.servicesHandle = [GMSServices sharedServices];

  // Log the required open source licenses! Yes, just NSLog-ing them is not enough but is good for a
  // demo.
  NSLog(@"Open source licenses:\n%@", [GMSServices openSourceLicenseInfo]);

  return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
  UISceneConfiguration *configuration =
      [UISceneConfiguration configurationWithName:@"Default Configuration"
                                      sessionRole:connectingSceneSession.role];
  configuration.delegateClass = [DemoSceneDelegate class];
  return configuration;
}

@end
