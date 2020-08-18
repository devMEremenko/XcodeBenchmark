//
//  VKSdk.h
//
//  Copyright (c) 2014 VK.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  --------------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
#import "VKAccessToken.h"
#import "VKPermissions.h"
#import "VKUtil.h"
#import "VKApi.h"
#import "VKApiConst.h"
#import "VKSdkVersion.h"
#import "VKCaptchaViewController.h"
#import "VKRequest.h"
#import "VKBatchRequest.h"
#import "NSError+VKError.h"
#import "VKApiModels.h"
#import "VKUploadImage.h"
#import "VKShareDialogController.h"
#import "VKActivity.h"
#import "VKAuthorizationResult.h"

/**
 Options used for authorization.
 */
typedef NS_OPTIONS(NSUInteger, VKAuthorizationOptions) {
    ///This option is passed by default. You will have unlimited in time access to user data
    VKAuthorizationOptionsUnlimitedToken = 1 << 0,
    ///Pass this option to disable usage of SFSafariViewController
    VKAuthorizationOptionsDisableSafariController = 1 << 1,
};

/**
 SDK events delegate protocol.
 
 This protocol may be implemented by any count of objects, but don't forget unregistering deallocated delegates.
 */
@protocol VKSdkDelegate <NSObject>
@required

/**
 Notifies about authorization was completed, and returns authorization result with new token or error.
 
 @param result contains new token or error, retrieved after VK authorization.
 */
- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result;

/**
 Notifies about access error. For example, this may occurs when user rejected app permissions through VK.com
 */
- (void)vkSdkUserAuthorizationFailed;

@optional

/**
 Notifies about authorization state was changed, and returns authorization result with new token or error.
 
 If authorization was successfull, also contains user info.
 
 @param result contains new token or error, retrieved after VK authorization
 */
- (void)vkSdkAuthorizationStateUpdatedWithResult:(VKAuthorizationResult *)result;

/**
 Notifies about access token has been changed
 
 @param newToken new token for API requests
 @param oldToken previous used token
 */
- (void)vkSdkAccessTokenUpdated:(VKAccessToken *)newToken oldToken:(VKAccessToken *)oldToken;

/**
 Notifies about existing token has expired (by timeout). This may occurs if you requested token without no_https scope.
 
 @param expiredToken old token that has expired.
 */
- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken;

@end

/**
 SDK UI delegate protocol.
 
 This delegate used for managing UI events, when SDK required user action.
 */
@protocol VKSdkUIDelegate <NSObject>
/**
 Pass view controller that should be presented to user. Usually, it's an authorization window.
 
 @param controller view controller that must be shown to user
 */
- (void)vkSdkShouldPresentViewController:(UIViewController *)controller;

/**
 Calls when user must perform captcha-check.
 If you implementing this method by yourself, call -[VKError answerCaptcha:] method for captchaError with user entered answer.
 
 @param captchaError error returned from API. You can load captcha image from <b>captchaImg</b> property.
 */
- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError;

@optional
/**
 * Called when a controller presented by SDK will be dismissed.
 */
- (void)vkSdkWillDismissViewController:(UIViewController *)controller;

/**
 * Called when a controller presented by SDK did dismiss.
 */
- (void)vkSdkDidDismissViewController:(UIViewController *)controller;

@end


/**
 Entry point for using VK sdk. Should be initialized at application start.
 
 Typical scenario of using SDK is next:
 
 1) Register new standalone application on https://vk.com/editapp?act=create
 
 2) Setup your application delegate and Info.plist as described on project page: https://github.com/VKCOM/vk-ios-sdk#how-to-set-up-vk-ios-sdk
 
 3) Initialize SDK with your VK application ID.
 
    VKSdk *sdkInstance = [VKSdk initializeWithAppId:VK_APP_ID];
 
 4) Register required SDK-delegates (VKSdkDelegate) and single UI-delegate (VKSdkUIDelegate).
 
    [sdkInstance registerDelegate:self];
    [sdkInstance setUiDelegate:self];
 
 5) Check if user already authorized.
 
    [VKSdk wakeUpSession:SCOPE completeBlock:^(VKAuthorizationState state, NSError *error) {
        switch (state) {
            case VKAuthorizationAuthorized:
                // User already autorized, and session is correct
                break;
 
            case VKAuthorizationInitialized:
                // User not yet authorized, proceed to next step
                break;
 
            default:
            // Probably, network error occured, try call +[VKSdk wakeUpSession:completeBlock:] later
            break;
        }
    }];
 
 6) If user is not authorized, call +[VKSdk authorize:] method with required scope (permission for token you required).
 
    [VKSdk authorize:@[VK_PER_FRIENDS, VK_PER_WALL]];
 
 7) You wait for -[VKSdkDelegate vkSdkAccessAuthorizationFinishedWithResult:] method called.
 
    - (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result {
        if (result.token) {
            // User successfully authorized, you may start working with VK API
        } else if (result.error) {
            // User canceled authorization, or occured unresolving networking error. Reset your UI to initial state and try authorize user later
        }
    }
 
*/
@interface VKSdk : NSObject

///-------------------------------
/// @name Delegate
///-------------------------------

/// Delegate for managing user interaction, when SDK required
@property(nonatomic, readwrite, weak) id <VKSdkUIDelegate> uiDelegate;

/// Returns a last app_id used for initializing the SDK
@property(nonatomic, readonly, copy) NSString *currentAppId;

/// API version for making requests
@property(nonatomic, readonly, copy) NSString *apiVersion;

///-------------------------------
/// @name Initialization
///-------------------------------

/**
 Returns instance of VK sdk. You should never use that directly
 */
+ (instancetype)instance;

/**
 Returns YES if SDK was previously initialized with initializeWithAppId: method
 */
+ (BOOL)initialized;

/**
 Initialize SDK with responder for global SDK events with default api version from VK_SDK_API_VERSION
 
 @param appId your application id (if you haven't, you can create standalone application here https://vk.com/editapp?act=create )
*/
+ (instancetype)initializeWithAppId:(NSString *)appId;

/**
Initialize SDK with responder for global SDK events.
 
@param appId your application id (if you haven't, you can create standalone application here https://vk.com/editapp?act=create )
@param version if you want to use latest API version, pass required version here
*/
+ (instancetype)initializeWithAppId:(NSString *)appId
                         apiVersion:(NSString *)version;

/**
 Adds a weak object reference to an object implementing the VKSdkDelegate protocol.
 
 @param delegate your object implementing delegate protocol
 */
- (void)registerDelegate:(id <VKSdkDelegate>)delegate;

/**
 Removes an object reference SDK delegate.
 
 @param delegate your object implementing delegate protocol
 */
- (void)unregisterDelegate:(id <VKSdkDelegate>)delegate;

///-------------------------------
/// @name Authentication in VK
///-------------------------------

/**
 Starts authorization process to retrieve unlimited token. If VKapp is available in system, it will opens and requests access from user.
 Otherwise SFSafariViewController or webview will be opened for access request.
 
 @param permissions array of permissions for your applications. All permissions you can
*/
+ (void)authorize:(NSArray *)permissions;

/**
 Starts authorization process. If VKapp is available in system, it will opens and requests access from user.
 Otherwise SFSafariViewController or webview will be opened for access request.
 
 @param permissions array of permissions for your applications. All permissions you can
 @param options special options
 */
+ (void)authorize:(NSArray *)permissions withOptions:(VKAuthorizationOptions)options;

///-------------------------------
/// @name Access token methods
///-------------------------------

/**
 Returns token for API requests.
 
 @return Received access token or nil, if user not yet authorized
*/
+ (VKAccessToken *)accessToken;

///-------------------------------
/// @name Other methods
///-------------------------------

/**
 Checks passed URL for access token.
 
 @param passedUrl url from external application
 @param sourceApplication source application
 @return YES if parsed successfully
*/
+ (BOOL)processOpenURL:(NSURL *)passedUrl fromApplication:(NSString *)sourceApplication;


/**
 Checks if somebody logged in with SDK (call after wakeUpSession)
 */
+ (BOOL)isLoggedIn;

/**
 This method is trying to retrieve token from storage, and check application still permitted to use user access token
 */
+ (void)wakeUpSession:(NSArray *)permissions completeBlock:(void (^)(VKAuthorizationState state, NSError *error))wakeUpBlock;

/**
Forces logout using OAuth (with VKAuthorizeController). Removes all cookies for *.vk.com.
Has no effect for logout in VK app
*/
+ (void)forceLogout;

/**
* Checks if there is some application, which may process authorize url
*/
+ (BOOL)vkAppMayExists;

/**
Check existing permissions
@param permissions array of permissions you want to check
*/
- (BOOL)hasPermissions:(NSArray *)permissions;

/**
Enables or disables scheduling for requests
*/
+ (void)setSchedulerEnabled:(BOOL)enabled;

// Deny allocating more SDK
+ (instancetype)alloc NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end


@interface UIViewController (VKController)

- (void)vks_presentViewControllerThroughDelegate;

- (void)vks_viewControllerWillDismiss;

- (void)vks_viewControllerDidDismiss;

@end

@interface VKAccessToken (Private)

- (void)notifyTokenExpired;

@end
