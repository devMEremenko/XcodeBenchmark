/*
 * Copyright 2022 Google LLC. All rights reserved.
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

#import "GoogleMapsDemos/DemoSceneDelegate.h"

#import "GoogleMapsDemos/SampleListViewController.h"

@implementation DemoSceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  if (![scene isKindOfClass:[UIWindowScene class]]) {
    return;
  }
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  SampleListViewController *sampleListViewController = [[SampleListViewController alloc] init];

  UINavigationController *rootNavigationController =
      [[UINavigationController alloc] initWithRootViewController:sampleListViewController];

  UIViewController *detailController = [[UIViewController alloc] init];

  self.splitViewController = [[UISplitViewController alloc] init];
  self.splitViewController.delegate = sampleListViewController;
  self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
  self.splitViewController.viewControllers = @[ rootNavigationController, detailController ];

  self.window.rootViewController = self.splitViewController;
  [self.window makeKeyAndVisible];
}

@end
