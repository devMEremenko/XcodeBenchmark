//
//  VKAuthorizeController.h
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

#import <UIKit/UIKit.h>
#import "VKSdk.h"
extern NSString *VK_AUTHORIZE_URL_STRING;

typedef NS_ENUM(NSInteger, VKAuthorizationType) {
    VKAuthorizationTypeWebView,
    VKAuthorizationTypeSafari,
    VKAuthorizationTypeApp
};

@interface VKNavigationController : UINavigationController

@end

@interface VKAuthorizationContext : VKObject
@property (nonatomic, readonly, strong) NSString *clientId;
@property (nonatomic, readonly, strong) NSString *displayType;
@property (nonatomic, readonly, strong) NSArray<NSString*> *scope;
@property (nonatomic, readonly) BOOL revoke;

/**
 Prepare context for building oauth url
 @param authType type of authorization will be used
 @param clientId id of the application
 @param displayType selected display type
 @param scope requested scope for application
 @param revoke If YES, user will see permissions list and allow to logout (if logged in already)
 @return Prepared context, which must be passed into buildAuthorizationURLWithContext: method
 */
+(instancetype) contextWithAuthType:(VKAuthorizationType) authType
                           clientId:(NSString*)clientId
                        displayType:(NSString*)displayType
                              scope:(NSArray<NSString*>*)scope
                             revoke:(BOOL) revoke;

@end

/**
Controller for authorization through webview (if VK app not available)
*/
@interface VKAuthorizeController : UIViewController

/**
Causes web view in standard UINavigationController be presented in SDK delegate
@param appId Identifier of VK application
@param permissions Permissions that user specified for application
@param revoke If YES, user will see permissions list and allow to logout (if logged in already)
@param displayType Defines view of authorization screen
*/
+ (void)presentForAuthorizeWithAppId:(NSString *)appId
                      andPermissions:(NSArray *)permissions
                        revokeAccess:(BOOL)revoke
                         displayType:(VKDisplayType)displayType;

/**
Causes web view in standard UINavigationController be presented for user validation
@param validationError validation error returned by API
*/
+ (void)presentForValidation:(VKError *)validationError;

+ (NSURL *)buildAuthorizationURLWithContext:(VKAuthorizationContext*) ctx;

@end
