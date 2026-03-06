//
//  GADRequestError.h
//  Google Mobile Ads SDK
//
//  Copyright 2011 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

/// Google AdMob Ads error domain.
FOUNDATION_EXPORT NSString *_Nonnull const GADErrorDomain;

/// NSError codes for GAD error domain.
typedef NS_ENUM(NSInteger, GADErrorCode) {
  /// The ad request is invalid. The localizedFailureReason error description will have more
  /// details. Typically this is because the ad did not have the ad unit ID or root view
  /// controller set.
  GADErrorInvalidRequest = 0,

  /// The ad request was successful, but no ad was returned.
  GADErrorNoFill = 1,

  /// There was an error loading data from the network.
  GADErrorNetworkError = 2,

  /// The ad server experienced a failure processing the request.
  GADErrorServerError = 3,

  /// The current device's OS is below the minimum required version.
  GADErrorOSVersionTooLow = 4,

  /// The request was unable to be loaded before being timed out.
  GADErrorTimeout = 5,

  /// The mediation response was invalid.
  GADErrorMediationDataError = 7,

  /// Error finding or creating a mediation ad network adapter.
  GADErrorMediationAdapterError = 8,

  /// Attempting to pass an invalid ad size to an adapter.
  GADErrorMediationInvalidAdSize = 10,

  /// Internal error.
  GADErrorInternalError = 11,

  /// Invalid argument error.
  GADErrorInvalidArgument = 12,

  /// Received invalid response.
  GADErrorReceivedInvalidResponse = 13,

  /// A mediation ad network adapter received an ad request, but did not fill. The adapter's error
  /// is included as an underlyingError.
  GADErrorMediationNoFill DEPRECATED_MSG_ATTRIBUTE(
      "This error will be replaced with GADErrorNoFill in a future version") = 9,

  /// Will not send request because the ad object has already been used.
  GADErrorAdAlreadyUsed = 19,

  /// Will not send request because the application identifier is missing.
  GADErrorApplicationIdentifierMissing = 20,
};
