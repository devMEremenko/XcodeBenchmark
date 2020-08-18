#import <UIKit/UIKit.h>

#import <UserMessagingPlatform/UMPRequestParameters.h>

/// SDK version string, of a form "major.minor.patch".
extern NSString *_Nonnull const UMPVersionString;

/// Consent status values.
typedef NS_ENUM(NSInteger, UMPConsentStatus) {
  UMPConsentStatusUnknown = 0,      ///< Unknown consent status.
  UMPConsentStatusRequired = 1,     ///< User consent required but not yet obtained.
  UMPConsentStatusNotRequired = 2,  ///< Consent not required.
  UMPConsentStatusObtained =
      3,  ///< User consent obtained, personalized vs non-personalized undefined.
};

/// Type of user consent.
typedef NS_ENUM(NSInteger, UMPConsentType) {
  UMPConsentTypeUnknown = 0,          ///< User consent either not obtained or personalized vs
                                      ///< non-personalized status undefined.
  UMPConsentTypePersonalized = 1,     ///< User consented to personalized ads.
  UMPConsentTypeNonPersonalized = 2,  ///< User consented to non-personalized ads.
};

/// State values for whether the user has a consent form available to them. To check whether form
/// status has changed, an update can be requested through
/// requestConsentInfoUpdateWithParameters:completionHandler.
typedef NS_ENUM(NSInteger, UMPFormStatus) {
  /// Whether a consent form is available is unknown. An update should be requested using
  /// requestConsentInfoUpdateWithParameters:completionHandler.
  UMPFormStatusUnknown = 0,

  /// Consent forms are available and can be loaded using [UMPConsentForm
  /// loadWithCompletionHandler:]
  UMPFormStatusAvailable = 1,

  /// Consent forms are unavailable. Showing a consent form is not required.
  UMPFormStatusUnavailable = 2,
};

/// Called when the consent info request completes. Error is nil on success, and non-nil if the
/// update failed.
typedef void (^UMPConsentInformationUpdateCompletionHandler)(NSError *_Nullable error);

/// Consent information. All methods must be called on the main thread.
@interface UMPConsentInformation : NSObject

/// The shared consent information instance.
@property(class, nonatomic, readonly, nonnull) UMPConsentInformation *sharedInstance;

/// The user's consent status. This value is cached between app sessions and can be read before
/// requesting updated parameters.
@property(nonatomic, readonly) UMPConsentStatus consentStatus;

/// The user's consent type. This value is cached between app sessions and can be read before
/// requesting updated parameters.
@property(nonatomic, readonly) UMPConsentType consentType;

/// Consent form status. This value defaults to UMPFormStatusUnknown and requires a call to
/// requestConsentInfoUpdateWithParameters:completionHandler to update.
@property(nonatomic, readonly) UMPFormStatus formStatus;

/// Requests consent information update. Must be called before loading a consent form.
- (void)requestConsentInfoUpdateWithParameters:(nullable UMPRequestParameters *)parameters
                             completionHandler:
                                 (nonnull UMPConsentInformationUpdateCompletionHandler)handler;

/// Clears all consent state from persistent storage.
- (void)reset;

@end
