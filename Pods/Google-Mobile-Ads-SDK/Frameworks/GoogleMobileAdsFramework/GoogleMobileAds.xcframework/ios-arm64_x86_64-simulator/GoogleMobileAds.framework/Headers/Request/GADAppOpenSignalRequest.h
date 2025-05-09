//
//  GADAppOpenSignalRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/Request/GADSignalRequest.h>

/// An app open signal request that can be used as input in server-to-server signal generation.
@interface GADAppOpenSignalRequest : GADSignalRequest

/// Returns an app open signal request.
/// @param signalType The type of signal to request.
- (nonnull instancetype)initWithSignalType:(nonnull NSString *)signalType;

@end
