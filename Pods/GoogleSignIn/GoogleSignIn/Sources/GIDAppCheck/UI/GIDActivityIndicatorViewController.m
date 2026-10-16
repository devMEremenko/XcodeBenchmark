/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GoogleSignIn/Sources/GIDAppCheck/UI/GIDActivityIndicatorViewController.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

#import <TargetConditionals.h>

@implementation GIDActivityIndicatorViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Medium gray with transparency
  self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.25];

  UIActivityIndicatorViewStyle style;
  if (@available(iOS 13.0, *)) {
    style = UIActivityIndicatorViewStyleLarge;
  } else {
    style = UIActivityIndicatorViewStyleGray;
  }
  _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
  _activityIndicator.color = UIColor.whiteColor;
  self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  [self.activityIndicator startAnimating];
  [self.view addSubview:self.activityIndicator];

  NSLayoutConstraint *centerX =
      [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor];
  NSLayoutConstraint *centerY =
      [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
  [NSLayoutConstraint activateConstraints:@[centerX, centerY]];
}

@end

#endif // TARGET_OS_IOS && !TARGET_OS_MACCATALYST
