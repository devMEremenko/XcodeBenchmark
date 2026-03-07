//
//  GADAdLoader+ServerToServer.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdLoader.h>

/// Provides server-to-server request methods.
@interface GADAdLoader (ServerToServer)

/// Returns an initialized ad loader.
///
/// @param rootViewController The root view controller used to present ad click actions.
- (nonnull instancetype)initWithRootViewController:(nullable UIViewController *)rootViewController;

/// Loads the ad and informs the delegate of the outcome.
- (void)loadWithAdResponseString:(nonnull NSString *)adResponseString;

@end
