#import <UserMessagingPlatform/UMPDebugSettings.h>

/// Parameters sent on updates to user consent info.
NS_SWIFT_NAME(RequestParameters)
@interface UMPRequestParameters : NSObject <NSCopying>

/// Indicates whether the user is tagged for under age of consent.
@property(nonatomic) BOOL tagForUnderAgeOfConsent NS_SWIFT_NAME(isTaggedForUnderAgeOfConsent);

/// Debug settings for the request.
@property(nonatomic, copy, nullable) UMPDebugSettings *debugSettings;

@end
