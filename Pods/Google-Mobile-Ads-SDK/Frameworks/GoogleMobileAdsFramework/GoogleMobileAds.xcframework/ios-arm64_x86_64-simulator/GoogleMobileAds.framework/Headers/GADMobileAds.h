//
//  GADMobileAds.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import <GoogleMobileAds/GADAudioVideoManager.h>
#import <GoogleMobileAds/GADInitializationStatus.h>
#import <GoogleMobileAds/GADRequestConfiguration.h>
#import <GoogleMobileAds/Mediation/GADVersionNumber.h>
#import <GoogleMobileAds/Request/GADSignal.h>
#import <GoogleMobileAds/Request/GADSignalRequest.h>

/// A block called with the initialization status when [GADMobileAds startWithCompletionHandler:]
/// completes or times out.
typedef void (^GADInitializationCompletionHandler)(GADInitializationStatus *_Nonnull status);

/// Completion handler for presenting Ad Inspector. Returns an error if a problem was detected
/// during presentation, or nil otherwise.
typedef void (^GADAdInspectorCompletionHandler)(NSError *_Nullable error);

/// Completion handler for signal request creation. Returns a signal or an error.
typedef void (^GADSignalCompletionHandler)(GADSignal *_Nullable signal, NSError *_Nullable error);

/// Google Mobile Ads SDK settings.
@interface GADMobileAds : NSObject

/// Returns the shared GADMobileAds instance.
+ (nonnull GADMobileAds *)sharedInstance;

/// Returns the Google Mobile Ads SDK's version number.
@property(nonatomic, readonly) GADVersionNumber versionNumber;

/// The application's audio volume. Affects audio volumes of all ads relative to other audio output.
/// Valid ad volume values range from 0.0 (silent) to 1.0 (current device volume). Defaults to 1.0.
///
/// Warning: Lowering your app's audio volume reduces video ad eligibility and may reduce your app's
/// ad revenue. You should only utilize this API if your app provides custom volume controls to the
/// user, and you should reflect the user's volume choice in this API.
@property(nonatomic, assign) float applicationVolume;

/// Indicates whether the application's audio is muted. Affects initial mute state for all ads.
/// Defaults to NO.
///
/// Warning: Muting your application reduces video ad eligibility and may reduce your app's ad
/// revenue. You should only utilize this API if your app provides a custom mute control to the
/// user, and you should reflect the user's mute decision in this API.
@property(nonatomic, assign) BOOL applicationMuted;

/// Manages the Google Mobile Ads SDK's audio and video settings.
@property(nonatomic, readonly, strong, nonnull) GADAudioVideoManager *audioVideoManager;

/// Request configuration that is common to all requests.
@property(nonatomic, readonly, strong, nonnull) GADRequestConfiguration *requestConfiguration;

/// Initialization status of the ad networks available to the Google Mobile Ads SDK.
@property(nonatomic, nonnull, readonly) GADInitializationStatus *initializationStatus;

/// Returns YES if the current SDK version is at least |major|.|minor|.|patch|. This method can be
/// used by libraries that depend on a specific minimum version of the Google Mobile Ads SDK to warn
/// developers if they have an incompatible version.
///
/// Available in Google Mobile Ads SDK 7.10 and onwards. Before calling this method check if the
/// GADMobileAds's shared instance responds to this method. Calling this method on a Google Mobile
/// Ads SDK lower than 7.10 can crash the app.
- (BOOL)isSDKVersionAtLeastMajor:(NSInteger)major
                           minor:(NSInteger)minor
                           patch:(NSInteger)patch
    NS_SWIFT_NAME(isSDKVersionAtLeast(major:minor:patch:));

/// Starts the Google Mobile Ads SDK. Call this method as early as possible to reduce latency on the
/// session's first ad request. Calls completionHandler when the GMA SDK and all mediation networks
/// are fully set up or if set-up times out. The Google Mobile Ads SDK starts on the first ad
/// request if this method is not called.
- (void)startWithCompletionHandler:(nullable GADInitializationCompletionHandler)completionHandler;

/// Disables automated SDK crash reporting. If not called, the SDK records the original exception
/// handler if available and registers a new exception handler. The new exception handler only
/// reports SDK related exceptions and calls the recorded original exception handler.
- (void)disableSDKCrashReporting;

/// Disables mediation adapter initialization during initialization of the GMA SDK. Calling this
/// method may negatively impact your ad performance and should only be called if you will not use
/// GMA SDK controlled mediation during this app session. This method must be called before
/// initializing the GMA SDK or loading ads and has no effect once the SDK has been initialized.
- (void)disableMediationInitialization;

/// Presents Ad Inspector. The device calling this API must be registered as a test device in order
/// to launch Ad Inspector. Set
/// GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers to enable test mode on
/// this device.
/// @param viewController A view controller to present Ad Inspector. If nil, uses the top view
/// controller of the app's main window.
/// @param completionHandler A handler to execute when Ad Inspector is closed.
- (void)presentAdInspectorFromViewController:(nullable UIViewController *)viewController
                           completionHandler:
                               (nullable GADAdInspectorCompletionHandler)completionHandler;

/// Registers a web view with the Google Mobile Ads SDK to improve in-app ad monetization of ads
/// within this web view.
- (void)registerWebView:(nonnull WKWebView *)webView;

/// Generates a signal that can be used as input in a server-to-server Google request. Calls
/// completionHandler asynchronously on the main thread once a signal has been generated or
/// when an error occurs.
/// @param request The signal request that will be used to generate the signal.
/// @param completionHandler A handler to execute when the signal generation is done.
+ (void)generateSignal:(nonnull GADSignalRequest *)request
     completionHandler:(nonnull GADSignalCompletionHandler)completionHandler;

@end
