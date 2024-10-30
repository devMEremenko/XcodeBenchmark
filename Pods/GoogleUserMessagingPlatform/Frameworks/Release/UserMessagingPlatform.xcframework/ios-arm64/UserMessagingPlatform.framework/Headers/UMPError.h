#import <Foundation/Foundation.h>

/// Error domain for all SDK errors.
extern NSErrorDomain _Nonnull const UMPErrorDomain;

/// Error codes used when making requests to update consent info.
typedef NS_ENUM(NSInteger, UMPRequestErrorCode) {
  UMPRequestErrorCodeInternal = 1,      ///< Internal error.
  UMPRequestErrorCodeInvalidAppID = 2,  ///< The application's app ID is invalid.
  UMPRequestErrorCodeNetwork = 3,       ///< Network error communicating with Funding Choices.
  UMPRequestErrorCodeMisconfiguration =
      4,  ///< A misconfiguration exists in the Funding Choices UI.
};

/// Error codes used when loading and showing forms.
typedef NS_ENUM(NSInteger, UMPFormErrorCode) {
  UMPFormErrorCodeInternal = 5,     ///< Internal error.
  UMPFormErrorCodeAlreadyUsed = 6,  ///< Form was already used.
  UMPFormErrorCodeUnavailable = 7,  ///< Form is unavailable.
  UMPFormErrorCodeTimeout = 8,      ///< Loading a form timed out.
  UMPFormErrorCodeInvalidViewController =
      9,  ///< Form cannot be presented from the provided view controller.
};
