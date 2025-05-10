//
//  GADDebugOptionsViewController.h
//  Google Mobile Ads SDK
//
//  Copyright 2016 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GADDebugOptionsViewController;

/// Delegate for the GADDebugOptionsViewController.
@protocol GADDebugOptionsViewControllerDelegate <NSObject>

/// Called when the debug options flow is finished.
- (void)debugOptionsViewControllerDidDismiss:(nonnull GADDebugOptionsViewController *)controller;

@end

/// Displays debug options to the user.
@interface GADDebugOptionsViewController : UIViewController

/// Creates and returns a GADDebugOptionsViewController object initialized with the ad unit ID.
/// @param adUnitID An ad unit ID for the Google Ad Manager account that is being configured with
/// debug options.
+ (nonnull instancetype)debugOptionsViewControllerWithAdUnitID:(nonnull NSString *)adUnitID;

/// Delegate for the debug options view controller.
@property(nonatomic, weak, nullable) IBOutlet id<GADDebugOptionsViewControllerDelegate> delegate;

@end
