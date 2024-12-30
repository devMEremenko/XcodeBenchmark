//
//  GADRequest+AdString.h
//  Google Mobile Ads SDK
//
//  Copyright 2022 Google LLC. All rights reserved.
//

#import <GoogleMobileAds/GADRequest.h>

/// Ad string request extension.
@interface GADRequest (AdString)

/// Ad string that represents an ad response. If set, the SDK will render this ad and ignore all
/// other targeting information set on this request.
@property(nonatomic, copy, nullable) NSString *adString;

@end
