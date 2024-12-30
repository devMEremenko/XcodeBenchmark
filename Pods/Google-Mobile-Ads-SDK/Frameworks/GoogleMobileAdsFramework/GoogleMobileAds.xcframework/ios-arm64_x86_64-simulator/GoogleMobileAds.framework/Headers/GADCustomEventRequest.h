//
//  GADCustomEventRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2012 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADRequest.h>
#import <UIKit/UIKit.h>

@class GADCustomEventExtras;

/// Specifies optional ad request targeting parameters that are provided by the publisher and are
/// forwarded to custom events for purposes of populating an ad request to a 3rd party ad network.
@interface GADCustomEventRequest : NSObject

/// Keywords set in GADRequest. Returns nil if no keywords are set.
@property(nonatomic, readonly, copy, nullable) NSArray *userKeywords;

/// The additional parameters set by the application. This property lets you pass additional
/// information from your application to your Custom Event object. To do so, create an instance of
/// GADCustomEventExtras to pass to GADRequest -registerAdNetworkExtras:. The instance should have
/// an NSDictionary set for a particular custom event label. That NSDictionary becomes the
/// additionalParameters here.
@property(nonatomic, readonly, copy, nullable) NSDictionary *additionalParameters;

/// Indicates whether the testing property has been set in GADRequest.
@property(nonatomic, readonly, assign) BOOL isTesting;

@end
