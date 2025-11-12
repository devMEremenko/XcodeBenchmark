//
//  GADSignalRequest.h
//  Google Mobile Ads SDK
//
//  Copyright 2024 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdNetworkExtras.h>
#import <UIKit/UIKit.h>

/// A signal request that can be used as input in server-to-server signal generation.
@interface GADSignalRequest : NSObject <NSCopying>

#pragma mark Additional Parameters For Ad Networks

/// Ad networks may have additional parameters they accept. To pass these parameters to them, create
/// the ad network extras object for that network, fill in the parameters, and register it here. The
/// ad network should have a header defining the interface for the 'extras' object to create. All
/// networks will have access to the basic settings you've set in this GADRequest. If you register
/// an extras object that is the same class as one you have registered before, the previous extras
/// will be overwritten.
- (void)registerAdNetworkExtras:(nonnull id<GADAdNetworkExtras>)extras;

/// Returns the network extras defined for an ad network.
- (nullable id<GADAdNetworkExtras>)adNetworkExtrasFor:(nonnull Class<GADAdNetworkExtras>)aClass;

/// Removes the extras for an ad network. |aClass| is the class which represents that network's
/// extras type.
- (void)removeAdNetworkExtrasFor:(nonnull Class<GADAdNetworkExtras>)aClass;

#pragma mark Publisher Provided

/// Scene object. Used in multiscene apps to request ads of the appropriate size. If this is nil,
/// uses the application's key window scene.
@property(nonatomic, nullable, weak) UIWindowScene *scene API_AVAILABLE(ios(13.0));

#pragma mark Contextual Information

/// Array of keyword strings. Keywords are words or phrases describing the current user activity
/// such as @"Sports Scores" or @"Football". Set this property to nil to clear the keywords.
@property(nonatomic, copy, nullable) NSArray<NSString *> *keywords;

/// URL string for a webpage whose content matches the app's primary content. This webpage content
/// is used for targeting and brand safety purposes.
@property(nonatomic, copy, nullable) NSString *contentURL;

/// URL strings for non-primary web content near an ad. Promotes brand safety and allows displayed
/// ads to have an app level rating (MA, T, PG, etc) that is more appropriate to neighboring
/// content.
@property(nonatomic, copy, nullable) NSArray<NSString *> *neighboringContentURLStrings;

#pragma mark Request Agent Information

/// String that identifies the ad request's origin. Third party libraries that reference the Mobile
/// Ads SDK should set this property to denote the platform from which the ad request originated.
/// For example, a third party ad network called "CoolAds network" that is mediating requests to the
/// Mobile Ads SDK should set this property as "CoolAds".
@property(nonatomic, copy, nullable) NSString *requestAgent;

#pragma mark Optional Targeting Information

/// Publisher provided ID.
@property(nonatomic, copy, nullable) NSString *publisherProvidedID;

/// Array of strings used to exclude specified categories in ad results.
@property(nonatomic, copy, nullable) NSArray<NSString *> *categoryExclusions;

/// Key-value pairs used for custom targeting.
@property(nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *customTargeting;

#pragma mark Ad Unit ID

/// The ad unit ID representing the placement in your app that will render the requested ad.
/// Create a new ad unit for every unique placement for improved targeting and reporting.
@property(nonatomic, copy, nullable) NSString *adUnitID;

#pragma mark Initialization

/// Initialization is only available from a subclass.
- (nonnull instancetype)init NS_UNAVAILABLE;

@end
