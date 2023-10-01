//
//  GADRequestConfiguration.h
//  Google Mobile Ads SDK
//
//  Copyright 2018 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>

/// Maximum ad content rating.
typedef NSString *GADMaxAdContentRating NS_TYPED_ENUM;

/// Rating for content suitable for general audiences, including families.
FOUNDATION_EXPORT GADMaxAdContentRating _Nonnull const GADMaxAdContentRatingGeneral;
/// Rating for content suitable for most audiences with parental guidance.
FOUNDATION_EXPORT GADMaxAdContentRating _Nonnull const GADMaxAdContentRatingParentalGuidance;
/// Rating for content suitable for teen and older audiences.
FOUNDATION_EXPORT GADMaxAdContentRating _Nonnull const GADMaxAdContentRatingTeen;
/// Rating for content suitable only for mature audiences.
FOUNDATION_EXPORT GADMaxAdContentRating _Nonnull const GADMaxAdContentRatingMatureAudience;

/// Add this constant to the testDevices property's array to receive test ads on the simulator.
FOUNDATION_EXPORT NSString *_Nonnull const GADSimulatorID;

/// Request configuration. The settings in this class will apply to all ad requests.
@interface GADRequestConfiguration : NSObject

/// The maximum ad content rating. All Google ads will have this content rating or lower.
@property(nonatomic, copy, nullable) GADMaxAdContentRating maxAdContentRating;

/// Identifiers corresponding to test devices which will always request test ads.
/// The test device identifier for the current device is logged to the console when the first
/// ad request is made.
@property(nonatomic, copy, nullable) NSArray<NSString *> *testDeviceIdentifiers;

/// [Optional] This property indicates whether the user is under the age of consent.
/// https://developers.google.com/admob/ios/targeting#users_under_the_age_of_consent.
///
/// If you set this property with @YES, a TFUA parameter will be included in all ad requests, and
/// you are indicating that you want ad requests to be handled in a manner suitable for users under
/// the age of consent. This parameter disables personalized advertising, including remarketing, for
/// all ad requests. It also disables requests to third-party ad vendors, such as ad measurement
/// pixels and third-party ad servers.
///
/// If you set this property with @NO, you are indicating that you don't want ad requests to be
/// handled in a manner suitable for users under the age of consent.
///
/// If you leave or reset this property as nil or unknown, ad requests will include no indication
/// of how you would like your ad requests to be handled in a manner suitable for users under the
/// age of consent.
@property(nonatomic, nullable, copy) NSNumber *tagForUnderAgeOfConsent;

/// [Optional] This property indicates whether you would like your app to be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA),
/// https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy.
///
/// If you set this property with @YES, you are indicating that your app should be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA).
///
/// If you set this property with @NO, you are indicating that your app should not be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA).
///
/// If you leave or reset this property as nil or unknown, ad requests will include no indication of
/// how you would like your app treated with respect to COPPA.
///
/// By setting this property, you certify that this notification is accurate and you are authorized
/// to act on behalf of the owner of the app. You understand that abuse of this setting may result
/// in termination of your Google account.
@property(nonatomic, nullable, copy) NSNumber *tagForChildDirectedTreatment;

/// Controls whether the Google Mobile Ads SDK Same App Key is enabled. The value set persists
/// across app sessions. The key is enabled by default.
- (void)setSameAppKeyEnabled:(BOOL)enabled;

#pragma mark - Deprecated

/// This method lets you specify whether the user is under the age of consent.
/// https://developers.google.com/admob/ios/targeting#users_under_the_age_of_consent.
///
/// If you call this method with YES, a TFUA parameter will be included in all ad requests. This
/// parameter disables personalized advertising, including remarketing, for all ad requests. It also
/// disables requests to third-party ad vendors, such as ad measurement pixels and third-party ad
/// servers.
- (void)tagForUnderAgeOfConsent:(BOOL)underAgeOfConsent
    GAD_DEPRECATED_MSG_ATTRIBUTE(
        "This method is deprecated. Use the tagForUnderAgeOfConsent property instead. Calling this "
        "method internally sets the property.");

/// [Optional] This method lets you specify whether you would like your app to be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA),
/// https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy.
///
/// If you call this method with YES, you are indicating that your app should be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA). If you call
/// this method with NO, you are indicating that your app should not be treated as child-directed
/// for purposes of the Children’s Online Privacy Protection Act (COPPA). If you do not call this
/// method, ad requests will include no indication of how you would like your app treated with
/// respect to COPPA.
///
/// By setting this method, you certify that this notification is accurate and you are authorized to
/// act on behalf of the owner of the app. You understand that abuse of this setting may result in
/// termination of your Google account.
- (void)tagForChildDirectedTreatment:(BOOL)childDirectedTreatment
    GAD_DEPRECATED_MSG_ATTRIBUTE(
        "This method is deprecated. Use the tagForChildDirectedTreatment property instead. "
        "PCalling this method internally sets the property.");

@end
