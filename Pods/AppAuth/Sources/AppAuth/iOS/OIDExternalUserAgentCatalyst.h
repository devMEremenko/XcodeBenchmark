/*! @file OIDExternalUserAgentCatalyst.h
   @brief AppAuth iOS SDK
   @copyright
       Copyright 2019 The AppAuth Authors. All Rights Reserved.
   @copydetails
       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
*/

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>

#import "OIDExternalUserAgent.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief A Catalyst specific external user-agent that uses `ASWebAuthenticationSession` to
       present the request.
*/
API_AVAILABLE(macCatalyst(13)) API_UNAVAILABLE(ios)
@interface OIDExternalUserAgentCatalyst : NSObject<OIDExternalUserAgent>

/*! @internal
    @brief Unavailable. Please use @c initWithPresentingViewController:
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/*! @brief The designated initializer.
    @param presentingViewController The view controller from which to present the
        \SFSafariViewController.
 */
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController
    NS_DESIGNATED_INITIALIZER;

/*! @brief Create an external user-agent which optionally uses a private authentication session.
    @param presentingViewController The view controller from which to present the browser.
    @param prefersEphemeralSession Whether the caller prefers to use a private authentication
        session. See @c ASWebAuthenticationSession.prefersEphemeralWebBrowserSession for more.
 */
- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController
                                  prefersEphemeralSession:(BOOL)prefersEphemeralSession;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_IOS || TARGET_OS_MACCATALYST
