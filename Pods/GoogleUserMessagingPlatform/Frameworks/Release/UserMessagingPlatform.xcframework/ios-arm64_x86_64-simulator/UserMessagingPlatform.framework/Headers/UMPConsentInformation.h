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

/// State values for whether the user needs to be provided a way to modify their privacy options.
typedef NS_ENUM(NSInteger, UMPPrivacyOptionsRequirementStatus) {
  /// Requirement unknown.
  UMPPrivacyOptionsRequirementStatusUnknown = 0,
  /// A way must be provided for the user to modify their privacy options.
  UMPPrivacyOptionsRequirementStatusRequired = 1,
  /// User does not need to modify their privacy options. Either consent is not required, or the
  /// consent type does not require modification.
  UMPPrivacyOptionsRequirementStatusNotRequired = 2,
};

/// Called when the consent info request completes. Error is nil on success, and non-nil if the
/// update failed.
typedef void (^UMPConsentInformationUpdateCompletionHandler)(NSError *_Nullable error);

/// Consent information. All methods must be called on the main thread.
@interface UMPConsentInformation : NSObject

/// The shared consent information instance.
@property(class, nonatomic, readonly, nonnull) UMPConsentInformation *sharedInstance;

/// The user's consent status. This value defaults to UMPConsentStatusUnknown until
/// requestConsentInfoUpdateWithParameters:completionHandler: is called, and defaults to the
/// previous session's value until |completionHandler| from
/// requestConsentInfoUpdateWithParameters:completionHandler: is called.
@property(nonatomic, readonly) UMPConsentStatus consentStatus;

/// Indicates whether the app has completed the necessary steps for gathering updated user consent.
/// Returns NO until requestConsentInfoUpdateWithParameters:completionHandler: is called. Returns
/// YES once requestConsentInfoUpdateWithParameters:completionHandler: is called and when
/// consentStatus is UMPConsentStatusNotRequired or UMPConsentStatusObtained.
@property(nonatomic, readonly) BOOL canRequestAds;

/// Consent form status. This value defaults to UMPFormStatusUnknown and requires a call to
/// requestConsentInfoUpdateWithParameters:completionHandler: to update.
@property(nonatomic, readonly) UMPFormStatus formStatus;

/// Privacy options requirement status. This value defaults to
/// UMPPrivacyOptionsRequirementStatusUnknown until
/// requestConsentInfoUpdateWithParameters:completionHandler: is called, and defaults to the
/// previous session's value until |completionHandler| from
/// requestConsentInfoUpdateWithParameters:completionHandler: is called.
@property(nonatomic, readonly) UMPPrivacyOptionsRequirementStatus privacyOptionsRequirementStatus;

/// Requests consent information update. Must be called in every app session before checking the
/// user's consentStatus or loading a consent form. After calling this method, consentStatus will be
/// updated synchronously to hold the consent state from the previous app session, if one exists.
/// consentStatus may be updated again immediately before the completion handler is called.
- (void)requestConsentInfoUpdateWithParameters:(nullable UMPRequestParameters *)parameters
                             completionHandler:
                                 (nonnull UMPConsentInformationUpdateCompletionHandler)handler;

/// Clears all consent state from persistent storage.
- (void)reset;

@end
