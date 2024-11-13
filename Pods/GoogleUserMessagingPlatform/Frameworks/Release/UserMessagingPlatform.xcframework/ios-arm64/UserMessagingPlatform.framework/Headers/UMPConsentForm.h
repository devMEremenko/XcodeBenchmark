#import <UserMessagingPlatform/UMPConsentInformation.h>

@class UMPConsentForm;

/// Provides a nonnull consentForm and a nil error if the load succeeded. Provides a nil
/// consentForm and a nonnull error if the load failed.
typedef void (^UMPConsentFormLoadCompletionHandler)(UMPConsentForm *_Nullable consentForm,
                                                    NSError *_Nullable error);

/// Called after presentation of a UMPConsentForm finishes.
typedef void (^UMPConsentFormPresentCompletionHandler)(NSError *_Nullable error);

/// A single use consent form object.
@interface UMPConsentForm : NSObject
/// Loads a consent form and calls completionHandler on completion. Must be called on the
/// main queue.
+ (void)loadWithCompletionHandler:(nonnull UMPConsentFormLoadCompletionHandler)completionHandler;

/// Loads a consent form and immediately presents it from the provided viewController if
/// UMPConsentInformation.sharedInstance.consentStatus is UMPConsentStatusRequired. Calls
/// completionHandler after the user selects an option and the form is dismissed, or on the next run
/// loop if no form is presented. Must be called on the main queue.
+ (void)loadAndPresentIfRequiredFromViewController:(nonnull UIViewController *)viewController
                                 completionHandler:(nullable UMPConsentFormPresentCompletionHandler)
                                                       completionHandler;

/// Presents a privacy options form from the provided viewController if
/// UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus is
/// UMPPrivacyOptionsRequirementStatusRequired. Calls completionHandler with nil error after the
/// user selects an option and the form is dismissed, or on the next run loop with a non-nil error
/// if no form is presented. Must be called on the main queue.
///
/// This method should only be called in response to a user input to request a privacy options form
/// to be shown. The privacy options form is preloaded by the SDK automatically when a form becomes
/// available. If no form is preloaded, the SDK will invoke the completionHandler on the next run
/// loop, but will asynchronously retry to load one.
+ (void)presentPrivacyOptionsFormFromViewController:(nonnull UIViewController *)viewController
                                  completionHandler:
                                      (nullable UMPConsentFormPresentCompletionHandler)
                                          completionHandler;

/// Unavailable. Use +loadWithCompletionHandler: instead.
- (nullable instancetype)init NS_UNAVAILABLE;

/// Presents the full screen consent form over viewController. The form is dismissed and
/// completionHandler is called after the user selects an option.
/// UMPConsentInformation.sharedInstance.consentStatus is updated prior to completionHandler being
/// called. completionHandler is called on the main queue.
- (void)presentFromViewController:(nonnull UIViewController *)viewController
                completionHandler:
                    (nullable UMPConsentFormPresentCompletionHandler)completionHandler;
@end
