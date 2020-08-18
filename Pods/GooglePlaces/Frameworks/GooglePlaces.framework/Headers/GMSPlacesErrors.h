//
//  GMSPlacesErrors.h
//  Google Places SDK for iOS
//
//  Copyright 2016 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://developers.google.com/maps/terms
//

/**
 * \defgroup PlacesErrors GMSPlacesErrors
 * @{
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain used for Places SDK errors.
 */
extern NSString *const kGMSPlacesErrorDomain;

/**
 * Error codes for |kGMSPlacesErrorDomain|.
 */
typedef NS_ENUM(NSInteger, GMSPlacesErrorCode) {
  /**
   * Something went wrong with the connection to the Places API server.
   */
  kGMSPlacesNetworkError = -1,
  /**
   * The Places API server returned a response that we couldn't understand.
   * <p>
   * If you believe this error represents a bug, please file a report using the instructions on our
   * <a href="https://developers.google.com/places/ios-sdk/support">community and support page</a>.
   */
  kGMSPlacesServerError = -2,
  /**
   * An internal error occurred in the Places SDK library.
   * <p>
   * If you believe this error represents a bug, please file a report using the instructions on our
   * <a href="https://developers.google.com/places/ios-sdk/support">community and support page</a>.
   */
  kGMSPlacesInternalError = -3,
  /**
   * Operation failed due to an invalid (malformed or missing) API key.
   * <p>
   * See the <a href="https://developers.google.com/places/ios-sdk/start">developer's guide</a>
   * for information on creating and using an API key.
   */
  kGMSPlacesKeyInvalid = -4,
  /**
   * Operation failed due to an expired API key.
   * <p>
   * See the <a href="https://developers.google.com/places/ios-sdk/start">developer's guide</a>
   * for information on creating and using an API key.
   */
  kGMSPlacesKeyExpired = -5,
  /**
   * Operation failed due to exceeding the quota usage limit.
   * <p>
   * See the <a href="https://developers.google.com/places/ios-sdk/usage">usage limits guide</a>
   * for information on usage limits and how to request a higher limit.
   */
  kGMSPlacesUsageLimitExceeded = -6,
  /**
   * Operation failed due to exceeding the usage rate limit for the API key.
   * <p>
   * This status code shouldn't be returned during normal usage of the API. It relates to usage of
   * the API that far exceeds normal request levels. See the <a
   * href="https://developers.google.com/places/ios-sdk/usage">usage limits guide</a> for more
   * information.
   */
  kGMSPlacesRateLimitExceeded = -7,
  /**
   * Operation failed due to exceeding the per-device usage rate limit.
   * <p>
   * This status code shouldn't be returned during normal usage of the API. It relates to usage of
   * the API that far exceeds normal request levels. See the <a
   * href="https://developers.google.com/places/ios-sdk/usage">usage limits guide</a> for more
   * information.
   */
  kGMSPlacesDeviceRateLimitExceeded = -8,
  /**
   * The Places API service for iOS is not enabled.
   * <p>
   * See the <a href="https://developers.google.com/places/ios-sdk/start">developer's guide</a>
   * to learn how to set up the Places SDK for iOS or the
   * <a href="https://developers.google.com/places/ios-sdk/client-migration">migration guide</a>
   * if you are migrating from an earlier version.
   */
  kGMSPlacesAccessNotConfigured = -9,
  /**
   * The application's bundle identifier does not match one of the allowed iOS applications for the
   * API key.
   * <p>
   * See the <a href="https://developers.google.com/places/ios-sdk/start">developer's guide</a>
   * for how to configure bundle restrictions on API keys.
   */
  kGMSPlacesIncorrectBundleIdentifier = -10,
  /**
   * The Places SDK could not find the user's location. This may be because the user has not allowed
   * the application to access location information.
   */
  kGMSPlacesLocationError = -11,
  /**
   * The Places SDK could not process the invalid request.
   * <p>
   * If you believe this error represents a bug, please file a report using the instructions on our
   * <a href="https://developers.google.com/places/ios-sdk/support">community and support page</a>.
   */
  kGMSPlacesInvalidRequest = -12
};

NS_ASSUME_NONNULL_END

/**@}*/
