//
//  GADQueryInfo.h
//  Google Mobile Ads SDK
//
//  Copyright 2019 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADAdFormat.h>
#import <GoogleMobileAds/GADRequest.h>

@class GADQueryInfo;

/// Completion handler for query creation. Returns query info or an error.
typedef void (^GADQueryInfoCreationCompletionHandler)(GADQueryInfo *_Nullable queryInfo,
                                                      NSError *_Nullable error);

/// Query info used in requests.
@interface GADQueryInfo : NSObject

/// Query string used in requests.
@property(nonatomic, readonly, nonnull) NSString *query;

#pragma mark Deprecated

/// Deprecated. Use +[GADMobileAds generateSignal:completionHandler:] instead.
///
/// Creates query info that can be used as input in a Google request. Calls completionHandler
/// asynchronously on the main thread once query info has been created or when an error occurs.
+ (void)createQueryInfoWithRequest:(nullable GADRequest *)request
                          adFormat:(GADAdFormat)adFormat
                 completionHandler:(nonnull GADQueryInfoCreationCompletionHandler)completionHandler
    GAD_DEPRECATED_MSG_ATTRIBUTE("Use +[GADMobileAds generateSignal:completionHandler:] instead.");

/// Deprecated. Use +[GADMobileAds generateSignal:completionHandler:] instead. Set adUnitID in the
/// GADSignalRequest subclass.
///
/// Creates query info for adUnitID that can be used as input in a Google
/// request. Calls completionHandler asynchronously on the main thread once query info has been
/// created or when an error occurs.
+ (void)createQueryInfoWithRequest:(nullable GADRequest *)request
                          adFormat:(GADAdFormat)adFormat
                          adUnitID:(nonnull NSString *)adUnitID
                 completionHandler:(nonnull GADQueryInfoCreationCompletionHandler)completionHandler
    GAD_DEPRECATED_MSG_ATTRIBUTE("Use +[GADMobileAds generateSignal:completionHandler:] instead. "
                                 "Set adUnitID in the GADSignalRequest subclass.");

@end
