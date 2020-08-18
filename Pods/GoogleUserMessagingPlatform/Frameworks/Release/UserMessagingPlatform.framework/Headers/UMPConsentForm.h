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
