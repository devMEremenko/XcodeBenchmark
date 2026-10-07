//
//  VKSdk.m
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

#ifdef DEBUG

#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]

#else

#define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])

#endif

#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)

#import <SafariServices/SafariServices.h>
#import "VKSdk.h"
#import "VKAuthorizeController.h"
#import "VKRequestsScheduler.h"

@interface VKWeakDelegate : NSProxy <VKSdkDelegate>
@property(nonatomic, weak) id <VKSdkDelegate> weakTarget;

+ (instancetype)with:(id <VKSdkDelegate>)delegate;

- (BOOL)isEqualTarget:(id <VKSdkDelegate>)delegate;

@end

@interface VKSdk () <SFSafariViewControllerDelegate>

@property(nonatomic, readonly, strong) NSMutableArray *sdkDelegates;

@property(nonatomic, assign) VKAuthorizationState authState;
@property(nonatomic, assign) VKAuthorizationOptions lastKnownOptions;

@property(nonatomic, readwrite, copy) NSString *currentAppId;
@property(nonatomic, readwrite, copy) NSString *apiVersion;
@property(nonatomic, readwrite, strong) VKAccessToken *accessToken;
@property(nonatomic, weak) UIViewController *presentedSafariViewController;

@property(nonatomic, strong) NSSet *permissions;
@end

@interface VKRequest ()
@property(nonatomic, readwrite, strong) VKAccessToken *specialToken;
@end


@implementation VKSdk

static VKSdk *vkSdkInstance = nil;
static NSArray *kSpecialPermissions = nil;
static NSString *VK_ACCESS_TOKEN_DEFAULTS_KEY = @"VK_ACCESS_TOKEN_DEFAULTS_KEY_DONT_TOUCH_THIS_PLEASE";


#pragma mark Initialization

+ (void)initialize {
    ZAssert([VKSdk class] == self, @"Subclassing is not welcome");
}

+ (instancetype)instance {
    ZAssert(vkSdkInstance, @"VKSdk should be initialized. Use [VKSdk initialize:delegate] method");
    return vkSdkInstance;
}

+ (BOOL)initialized {
    return vkSdkInstance != nil;
}

+ (instancetype)initializeWithAppId:(NSString *)appId {
    return [self initializeWithAppId:appId apiVersion:VK_SDK_API_VERSION];
}

+ (instancetype)initializeWithAppId:(NSString *)appId apiVersion:(NSString *)version {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vkSdkInstance = [(VKSdk *) [super alloc] initUniqueInstance];
        kSpecialPermissions = @[VK_PER_OFFLINE, VK_PER_NOHTTPS, VK_PER_NOTIFY, VK_PER_EMAIL];
    });

    vkSdkInstance.currentAppId = appId;
    vkSdkInstance.apiVersion = version;

    [[VKRequestsScheduler instance] setEnabled:YES];
    return vkSdkInstance;
}

- (void)registerDelegate:(id <VKSdkDelegate>)delegate {
    for (VKWeakDelegate *d in self.sdkDelegates) {
        if ([d isEqualTarget:delegate]) {
            return;
        }
    }
    [self.sdkDelegates addObject:[VKWeakDelegate with:delegate]];
}

- (void)unregisterDelegate:(id <VKSdkDelegate>)delegate {
    for (VKWeakDelegate *d in [self.sdkDelegates copy]) {
        if ([d isEqualTarget:delegate]) {
            [self.sdkDelegates removeObject:d];
        }
        if (d.weakTarget == nil) {
            [self.sdkDelegates removeObject:d];
        }
    }
}

#pragma mark Authorization

+ (void)authorize:(NSArray *)permissions {
    [self authorize:permissions withOptions:VKAuthorizationOptionsUnlimitedToken];
}

+ (void)authorize:(NSArray *)permissions withOptions:(VKAuthorizationOptions)options {
    permissions = permissions ?: @[];
    NSMutableSet *permissionsSet = [NSMutableSet setWithArray:permissions];

    if (options & VKAuthorizationOptionsUnlimitedToken) {
        [permissionsSet addObject:VK_PER_OFFLINE];
    }
    VKSdk *instance = [VKSdk instance];
    instance.lastKnownOptions = options;

    if ([self accessToken] && [instance.permissions isEqualToSet:permissionsSet]) {
        instance.accessToken = [self accessToken];
        return;
    }
    if (instance.authState == VKAuthorizationAuthorized) {
        instance.authState = VKAuthorizationInitialized;
    }
    
    instance.permissions = [permissionsSet copy];
    permissions = [permissionsSet allObjects];

    BOOL providersEnabled = !(options & VKAuthorizationOptionsDisableProviders);

    BOOL vkApp = [self vkAppMayExists]
            && instance.authState == VKAuthorizationInitialized && providersEnabled;

    BOOL safariEnabled = !(options & VKAuthorizationOptionsDisableSafariController);

    NSString *clientId = instance.currentAppId;
    VKAuthorizationContext *authContext =
    [VKAuthorizationContext contextWithAuthType:vkApp ? VKAuthorizationTypeApp : VKAuthorizationTypeSafari
                                       clientId:clientId
                                    displayType:VK_DISPLAY_MOBILE
                                          scope:permissions
                                         revoke:YES];
    NSURL *urlToOpen = [VKAuthorizeController buildAuthorizationURLWithContext:authContext];

    if (vkApp) {
        
        UIApplication *application = [UIApplication sharedApplication];
        
        // Since iOS 9 there is a dialog asking user if he wants to allow the running app
        // to open another app via URL. If user rejects, then no VK SDK callbacks are called.
        // Fixing this using new -[UIApplication openURL:options:completionHandler:] method (iOS 10+).
        
#ifdef __AVAILABILITY_INTERNAL__IPHONE_10_0_DEP__IPHONE_10_0
        if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            
            NSDictionary *options = @{ UIApplicationOpenURLOptionUniversalLinksOnly: @NO };
            
            [application openURL:urlToOpen options:options completionHandler:^(BOOL success) {
                
                if (!success) {
                    
                    VKMutableAuthorizationResult *result = [VKMutableAuthorizationResult new];
                    result.state = VKAuthorizationError;
                    result.error = [NSError errorWithVkError:[VKError errorWithCode:VK_API_CANCELED]];
                    
                    [[VKSdk instance] notifyDelegate:@selector(vkSdkAccessAuthorizationFinishedWithResult:) obj:result];
                }
            }];
        } else {
            [application openURL:urlToOpen];
        }
#else
        [application openURL:urlToOpen];
#endif
    
        instance.authState = VKAuthorizationExternal;
    
    } else if (safariEnabled && [SFSafariViewController class] && instance.authState < VKAuthorizationSafariInApp) {
        SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL:urlToOpen];
        viewController.delegate = instance;
        [viewController vks_presentViewControllerThroughDelegate];
        instance.presentedSafariViewController = viewController;

        instance.authState = VKAuthorizationSafariInApp;
    } else {
        //Authorization through popup webview
        [VKAuthorizeController presentForAuthorizeWithAppId:clientId
                                             andPermissions:permissions
                                               revokeAccess:YES
                                                displayType:VK_DISPLAY_IOS];
        instance.authState = VKAuthorizationWebview;
    }
}

+ (BOOL)vkAppMayExists {
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:VK_AUTHORIZE_URL_STRING]];
}

#pragma mark Access token

+ (void)setAccessToken:(VKAccessToken *)token {
    [token saveTokenToDefaults:VK_ACCESS_TOKEN_DEFAULTS_KEY];

    id oldToken = vkSdkInstance.accessToken;
    if (!token && oldToken) {
        [VKAccessToken delete:VK_ACCESS_TOKEN_DEFAULTS_KEY];
    }

    vkSdkInstance.authState = token ? VKAuthorizationAuthorized : VKAuthorizationInitialized;
    vkSdkInstance.accessToken = token;
}

+ (VKAccessToken *)accessToken {
    return vkSdkInstance.accessToken;
}

+ (BOOL)processOpenURL:(NSURL *)passedUrl validation:(BOOL)validation {
    NSString *urlString = [passedUrl absoluteString];
    NSRange rangeOfHash = [urlString rangeOfString:@"#"];
    if (rangeOfHash.location == NSNotFound) {
        return NO;
    }

    VKSdk *instance = [self instance];

    void (^hideViews)(void) = ^{
        if (instance.presentedSafariViewController) {
            UIViewController *safariVC = instance.presentedSafariViewController;
            [safariVC vks_viewControllerWillDismiss];
            void (^dismissBlock)(void) = ^{
                [safariVC vks_viewControllerDidDismiss];
            };
            if (safariVC.isBeingDismissed) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), dismissBlock);
            } else {
                [safariVC.presentingViewController dismissViewControllerAnimated:YES completion:dismissBlock];
            }
            instance.presentedSafariViewController = nil;
        }
    };
    
    void (^notifyAuthorization)(VKAccessToken *, VKError *) = ^(VKAccessToken *token, VKError *error) {
        [self setAccessToken:token];
        
        VKAuthorizationState prevState = vkSdkInstance.authState;
        
        VKMutableAuthorizationResult *res = [VKMutableAuthorizationResult new];
        res.error = error ? [NSError errorWithVkError:error] : nil;
        res.token = token;
        res.state = vkSdkInstance.authState = error ? VKAuthorizationError : VKAuthorizationPending;
        if (token) {
            [instance requestSdkState:^(VKUser *visitor, NSInteger per, NSError *err) {
                if (visitor) {
                    VKAccessTokenMutable *mToken = (VKAccessTokenMutable *) [token mutableCopy];
                    mToken.permissions = [instance updatePermissions:per];
                    instance.permissions = [NSSet setWithArray:mToken.permissions ?: @[]];
                    mToken.localUser = visitor;

                    [self setAccessToken:mToken];
                    res.user = visitor;
                    res.token = mToken;
                    res.state = vkSdkInstance.authState = VKAuthorizationAuthorized;
                } else if (err) {
                    res.error = err;
                    res.state = VKAuthorizationError;
                    vkSdkInstance.authState = prevState;
                }
                [instance notifyDelegate:@selector(vkSdkAuthorizationStateUpdatedWithResult:) obj:res];
                hideViews();
            }            trackVisitor:YES token:token];
        } else {
            hideViews();
        }
        
        [instance notifyDelegate:@selector(vkSdkAccessAuthorizationFinishedWithResult:) obj:res];

    };

    NSString *parametersString = [urlString substringFromIndex:rangeOfHash.location + 1];
    if (parametersString.length == 0) {
        VKError *error = [VKError errorWithCode:VK_API_CANCELED];
        if (!validation) {
            notifyAuthorization(nil, error);
            [instance resetSdkState];
        }
        return NO;
    }
    NSDictionary *parametersDict = [VKUtil explodeQueryString:parametersString];
    BOOL inAppCheck = [[passedUrl host] isEqual:@"oauth.vk.com"];

    void (^throwError)(void) = ^{
        VKError *error = [VKError errorWithQuery:parametersDict];
        if (!validation) {
            notifyAuthorization(nil, error);
            [instance resetSdkState];
        }
    };

    BOOL result = YES;
    if (!inAppCheck && parametersDict[@"error"]) {
        if ([parametersDict[@"error_reason"] isEqual:@"sdk_error"] && instance.authState == VKAuthorizationExternal) {
            //Try internal authorize
            [self authorize:[instance.permissions allObjects]];
        } else {
            throwError();
        }
        result = NO;
    } else if (inAppCheck && (parametersDict[@"cancel"] || parametersDict[@"error"] || parametersDict[@"fail"])) {
        throwError();
        result = NO;
    } else if (inAppCheck && parametersDict[@"success"]) {
        if (parametersDict[@"access_token"]) {
            VKAccessToken *prevToken = [VKSdk accessToken];
            VKAccessTokenMutable *token = [VKAccessTokenMutable tokenWithToken:parametersDict[@"access_token"] ?: prevToken.accessToken
                                                                        secret:parametersDict[@"secret"] ?: prevToken.secret
                                                                        userId:parametersDict[@"user_id"] ?: prevToken.userId];
            token.expiresIn = prevToken.expiresIn;
            token.permissions = prevToken.permissions;
            token.httpsRequired = prevToken.httpsRequired;

            if (!validation) {
                notifyAuthorization(token, nil);
            } else {
                [self setAccessToken:token];
            }
        }
    } else {

        NSMutableString *newParametersString = [parametersString mutableCopy];
        [newParametersString appendFormat:@"&permissions=%@", [[instance.permissions allObjects] componentsJoinedByString:@","]];

        VKAccessToken *token = [VKAccessToken tokenFromUrlString:newParametersString];
        if (!token.accessToken) {
            result = NO;
        } else {
            notifyAuthorization(token, nil);
        }
    }
    if (!result) {
        hideViews();
    }
    return result;
}

+ (BOOL)processOpenURL:(NSURL *)passedUrl fromApplication:(NSString *)sourceApplication {
    if ([sourceApplication isEqualToString:VK_DEBUG_CLIENT_BUNDLE]
            || [sourceApplication isEqualToString:VK_ORIGINAL_CLIENT_BUNDLE]
            || [sourceApplication isEqualToString:VK_ORIGINAL_HD_CLIENT_BUNDLE]
            || [passedUrl.scheme isEqualToString:[NSString stringWithFormat:@"vk%@", vkSdkInstance.currentAppId]]) {
        return [self processOpenURL:passedUrl validation:NO];
    }
    return NO;
}

+ (BOOL)processOpenInternalURL:(NSURL *)passedUrl validation:(BOOL)validation {
    return [self processOpenURL:passedUrl validation:validation];
}

+ (void)forceLogout {
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];

    for (NSHTTPCookie *cookie in cookies)
        if (NSNotFound != [cookie.domain rangeOfString:@"vk.com"].location) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage]
                    deleteCookie:cookie];
        }
    [VKAccessToken delete:VK_ACCESS_TOKEN_DEFAULTS_KEY];

    if (vkSdkInstance) {
        vkSdkInstance.accessToken = nil;
        vkSdkInstance.permissions = nil;
        vkSdkInstance.authState = VKAuthorizationInitialized;
    }
}

+ (BOOL)isLoggedIn {
    if (vkSdkInstance.accessToken && ![vkSdkInstance.accessToken isExpired]) return true;
    return false;
}

+ (void)wakeUpSession:(NSArray *)permissions completeBlock:(void (^)(VKAuthorizationState, NSError *error))wakeUpBlock {
    VKAccessToken *token = [self accessToken] ?: [VKAccessToken savedToken:VK_ACCESS_TOKEN_DEFAULTS_KEY];
    VKSdk *instance = [self instance];
    if (!token || token.isExpired) {
        [instance resetSdkState];
        wakeUpBlock(instance.authState, nil);
    } else {

        BOOL firstCall = instance.accessToken == nil;
        instance.accessToken = token;
        instance.authState = VKAuthorizationPending;

        [[VKSdk instance] requestSdkState:^(VKUser *visitor, NSInteger per, NSError *error) {

            instance.authState = VKAuthorizationUnknown;
            if (visitor) {
                VKAccessTokenMutable *mToken = (VKAccessTokenMutable *) [token mutableCopy];
                mToken.permissions = [instance updatePermissions:per];
                instance.permissions = [NSSet setWithArray:mToken.permissions ?: @[]];
                mToken.localUser = visitor;
                instance.accessToken = mToken;

                if ([instance hasPermissions:permissions]) {
                    instance.authState = VKAuthorizationAuthorized;
                } else {
                    [instance resetSdkState];
                }
            } else if (error) {
                instance.authState = VKAuthorizationError;
                instance.accessToken = nil;

                VKError *vkError = error.vkError;
                if (vkError.errorCode == 5) {
                    //Remove token from storage
                    [self setAccessToken:nil];
                    instance.authState = VKAuthorizationInitialized;
                }
            }
            wakeUpBlock(instance.authState, error);

        } trackVisitor:firstCall token:token];

    }

}

- (BOOL)hasPermissions:(NSArray *)permissions {
    NSMutableArray *mutablePermissions = permissions ? [permissions mutableCopy] : [NSMutableArray new];
    [mutablePermissions removeObjectsInArray:kSpecialPermissions];

    BOOL allExisted = YES;
    NSSet *tokenPermission = [NSSet setWithArray:self.accessToken.permissions];
    for (NSString *p in mutablePermissions) {
        if (![tokenPermission containsObject:p]) {
            allExisted = NO;
            break;
        }
    }
    return allExisted;
}


- (NSArray *)updatePermissions:(NSInteger)appPermissions {
    NSMutableSet *permissions = [NSMutableSet setWithArray:VKParseVkPermissionsFromInteger(appPermissions)];
    for (NSString *sPermission in kSpecialPermissions) {
        if ([self.permissions containsObject:sPermission]) {
            [permissions addObject:sPermission];
        }
    }
    return [permissions allObjects];
}

+ (void)setSchedulerEnabled:(BOOL)enabled {
    [[VKRequestsScheduler instance] setEnabled:enabled];
}


#pragma mark - Instance methods

- (instancetype)initUniqueInstance {
    self = [super init];
    [self resetSdkState];
    _sdkDelegates = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleDidBecomeActive {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.authState == VKAuthorizationExternal) {
            [VKSdk authorize:[vkSdkInstance.permissions allObjects] withOptions:vkSdkInstance.lastKnownOptions];
        }
    });
}

- (NSString *)currentAppId {
    return _currentAppId;
}

- (void)requestSdkState:(void (^)(VKUser *visitor, NSInteger permissions, NSError *error))infoCallback trackVisitor:(BOOL)trackVisitor token:(VKAccessToken *)token {
    NSString *code = [NSString stringWithFormat:@"return {permissions:API.account.getAppPermissions(),user:API.users.get({fields : \"photo_50,photo_100,photo_200\"})[0],%1$@};", trackVisitor ? @"stats:API.stats.trackVisitor()," : @""];
    VKRequest *req = [VKRequest requestWithMethod:@"execute" parameters:@{@"code" : code}];
    req.specialToken = token;
    req.preventThisErrorsHandling = @[@5];
    [req executeWithResultBlock:^(VKResponse *response) {
        VKUser *user = [[VKUser alloc] initWithDictionary:response.json[@"user"]];
        if (infoCallback) {
            infoCallback(user, [VK_ENSURE_NUM(response.json[@"permissions"]) integerValue], nil);
        }
    } errorBlock:^(NSError *error) {
        if (infoCallback) {
            infoCallback(nil, 0, error);
        }
    }];
}

- (void)notifyUserAuthorizationFailed:(VKError *)error {
    [self notifyDelegate:@selector(vkSdkUserAuthorizationFailed) obj:nil];
    [[self class] setAccessToken:nil];
    [self resetSdkState];
}

- (void)resetSdkState {
    self.permissions = nil;
    self.authState = VKAuthorizationInitialized;
    self.lastKnownOptions = 0;
    self.accessToken = nil;
}

- (void)notifyDelegate:(SEL)sel obj:(id)obj {
    for (VKWeakDelegate *del in [self.sdkDelegates copy]) {
        if ([del respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [del performSelector:sel withObject:obj];
#pragma clang diagnostic pop
        }
    }
}

- (void)setAccessToken:(VKAccessToken *)accessToken {
    VKAccessToken *old = _accessToken;
    _accessToken = accessToken;

    for (VKWeakDelegate *del in [self.sdkDelegates copy]) {
        if ([del respondsToSelector:@selector(vkSdkAccessTokenUpdated:oldToken:)]) {
            [del performSelector:@selector(vkSdkAccessTokenUpdated:oldToken:) withObject:self.accessToken withObject:old];
        }
    }
}

#pragma mark - SFSafariViewController delegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [[self class] processOpenURL:[NSURL URLWithString:@"#"] validation:NO];
}

@end

@implementation VKWeakDelegate {
    Class objectClass;
}

+ (instancetype)with:(id <VKSdkDelegate>)delegate {
    VKWeakDelegate *res = [[self alloc] initWithObject:delegate];
    return res;
}

- (instancetype)initWithObject:(id <VKSdkDelegate>)object {
    self.weakTarget = object;
    objectClass = [object class];
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSObject *targ = (id) self.weakTarget;
    if (targ) {
        return [targ methodSignatureForSelector:sel];
    } else {
        return [objectClass instanceMethodSignatureForSelector:sel];
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (self.weakTarget) {
        [invocation invokeWithTarget:self.weakTarget];
    }
}

- (BOOL)isEqualTarget:(id <VKSdkDelegate>)delegate {
    return _weakTarget == delegate;
}

@end


@implementation VKAccessToken (Private)

- (void)setAccessTokenRequiredHTTPS {
    VKAccessTokenMutable *token = (VKAccessTokenMutable *) [[VKSdk accessToken] mutableCopy];
    token.httpsRequired = YES;
    [VKSdk setAccessToken:token];
}

- (void)notifyTokenExpired {
    [[VKSdk instance] notifyDelegate:@selector(vkSdkTokenHasExpired:) obj:self];
}

@end


@implementation VKError (CaptchaRequest)

- (void)notifyCaptchaRequired {
    [[VKSdk instance].uiDelegate vkSdkNeedCaptchaEnter:self];
}

- (void)notifyAuthorizationFailed {
    [[VKSdk instance] notifyUserAuthorizationFailed:self];
}

@end


@implementation UIViewController (VKController)

- (void)vks_presentViewControllerThroughDelegate {
    [[VKSdk instance].uiDelegate vkSdkShouldPresentViewController:self];
}

- (void)vks_viewControllerWillDismiss {
    if ([[VKSdk instance].uiDelegate respondsToSelector:@selector(vkSdkWillDismissViewController:)]) {
        [[VKSdk instance].uiDelegate vkSdkWillDismissViewController:self];
    }
}

- (void)vks_viewControllerDidDismiss {
    if ([[VKSdk instance].uiDelegate respondsToSelector:@selector(vkSdkDidDismissViewController:)]) {
        [[VKSdk instance].uiDelegate vkSdkDidDismissViewController:self];
    }
}

@end
