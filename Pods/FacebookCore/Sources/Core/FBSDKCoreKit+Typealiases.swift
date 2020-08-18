// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import Foundation

// Typealiases for FBSDKCoreKit types to avoid having to import
// dependent libraries. At somepoint these will be likely
// become "wrapper" types that extend and enhance functionality
// in addition to exposing it. For now it suffices to simply expose
// them to the correct library aka. FacebookCore

/**
 Wrapper for `FBSDKCoreKit.AccessToken`

 - SeeAlso: `FBSDKCoreKit.AccessToken`
 */
public typealias AccessToken = FBSDKCoreKit.AccessToken

/**
 Wrapper for `FBSDKCoreKit.AppEvents`

 - SeeAlso: `FBSDKCoreKit.AppEvents`
 */
public typealias AppEvents = FBSDKCoreKit.AppEvents

/**
 Wrapper for `FBSDKCoreKit.AppLink`

 - SeeAlso: `FBSDKCoreKit.AppLink`
 */
public typealias AppLink = FBSDKCoreKit.AppLink

/**
 Wrapper for `FBSDKCoreKit.AppLinkNavigation`

 - SeeAlso: `FBSDKCoreKit.AppLinkNavigation`
 */
public typealias AppLinkNavigation = FBSDKCoreKit.AppLinkNavigation

/**
 Wrapper for `FBSDKCoreKit.AppLinkResolver`

 - SeeAlso: `FBSDKCoreKit.AppLinkResolver`
 */
public typealias AppLinkResolver = FBSDKCoreKit.AppLinkResolver

/**
 Wrapper for `FBSDKCoreKit.AppLinkReturnToRefererController`

 - SeeAlso: `FBSDKCoreKit.AppLinkReturnToRefererController`
 */
public typealias AppLinkReturnToRefererController = FBSDKCoreKit.AppLinkReturnToRefererController

/**
 Wrapper for `FBSDKCoreKit.AppLinkTarget`

 - SeeAlso: `FBSDKCoreKit.AppLinkTarget`
 */
public typealias AppLinkTarget = FBSDKCoreKit.AppLinkTarget

/**
 Wrapper for `FBSDKCoreKit.AppLinkURL`

 - SeeAlso: `FBSDKCoreKit.AppLinkURL`
 */
public typealias AppLinkURL = FBSDKCoreKit.AppLinkURL

/**
 Wrapper for `FBSDKCoreKit.AppLinkUtility`

 - SeeAlso: `FBSDKCoreKit.AppLinkUtility`
 */
public typealias AppLinkUtility = FBSDKCoreKit.AppLinkUtility

/**
 Wrapper for `FBSDKCoreKit.ApplicationDelegate`

 - SeeAlso: `FBSDKCoreKit.ApplicationDelegate`
 */
public typealias ApplicationDelegate = FBSDKCoreKit.ApplicationDelegate

/**
 Wrapper for `FBSDKCoreKit.CoreError`

 - SeeAlso: `FBSDKCoreKit.CoreError`
 */
public typealias CoreError = FBSDKCoreKit.CoreError

/**
 Wrapper for `FBSDKCoreKit.FBAppLinkReturnToRefererView`

 - SeeAlso: `FBSDKCoreKit.FBAppLinkReturnToRefererView`
 */
public typealias FBAppLinkReturnToRefererView = FBSDKCoreKit.FBAppLinkReturnToRefererView

/**
 Wrapper for `FBSDKCoreKit.FBButton`

 - SeeAlso: `FBSDKCoreKit.FBButton`
 */
public typealias FBButton = FBSDKCoreKit.FBButton

/**
 Wrapper for `FBSDKCoreKit.FBProfilePictureView`

 - SeeAlso: `FBSDKCoreKit.FBProfilePictureView`
 */
public typealias FBProfilePictureView = FBSDKCoreKit.FBProfilePictureView

/**
 Wrapper for `FBSDKCoreKit.GraphRequest`

 - SeeAlso: `FBSDKCoreKit.GraphRequest`
 */
public typealias GraphRequest = FBSDKCoreKit.GraphRequest

/**
 Wrapper for `FBSDKCoreKit.GraphRequestConnection`

 - SeeAlso: `FBSDKCoreKit.GraphRequestConnection`
 */
public typealias GraphRequestConnection = FBSDKCoreKit.GraphRequestConnection

/**
 Wrapper for `FBSDKCoreKit.GraphRequestDataAttachment`

 - SeeAlso: `FBSDKCoreKit.GraphRequestDataAttachment`
 */
public typealias GraphRequestDataAttachment = FBSDKCoreKit.GraphRequestDataAttachment

/**
 Wrapper for `FBSDKCoreKit.GraphRequestError`

 - SeeAlso: `FBSDKCoreKit.GraphRequestError`
 */
public typealias GraphRequestError = FBSDKCoreKit.GraphRequestError

/**
 Wrapper for `FBSDKCoreKit.HTTPMethod`

 - SeeAlso: `FBSDKCoreKit.HTTPMethod`
 */
public typealias HTTPMethod = FBSDKCoreKit.HTTPMethod

/**
 Wrapper for `FBSDKCoreKit.LoggingBehavior`

 - SeeAlso: `FBSDKCoreKit.LoggingBehavior`
 */
public typealias LoggingBehavior = FBSDKCoreKit.LoggingBehavior

/**
 Wrapper for `FBSDKCoreKit.MeasurementEvent`

 - SeeAlso: `FBSDKCoreKit.MeasurementEvent`
 */
public typealias MeasurementEvent = FBSDKCoreKit.MeasurementEvent

/**
 Wrapper for `FBSDKCoreKit.Profile`

 - SeeAlso: `FBSDKCoreKit.Profile`
 */
public typealias Profile = FBSDKCoreKit.Profile

/**
 Wrapper for `FBSDKCoreKit.Settings`

 - SeeAlso: `FBSDKCoreKit.Settings`
 */
public typealias Settings = FBSDKCoreKit.Settings

/**
 Wrapper for `FBSDKCoreKit.TestUsersManager`

 - SeeAlso: `FBSDKCoreKit.TestUsersManager`
 */
public typealias TestUsersManager = FBSDKCoreKit.TestUsersManager

/**
 Wrapper for `FBSDKCoreKit.Utility`

 - SeeAlso: `FBSDKCoreKit.Utility`
 */
public typealias Utility = FBSDKCoreKit.Utility

/**
 Wrapper for `FBSDKCoreKit.WebViewAppLinkResolver`

 - SeeAlso: `FBSDKCoreKit.WebViewAppLinkResolver`
 */
public typealias WebViewAppLinkResolver = FBSDKCoreKit.WebViewAppLinkResolver

// MARK: - Protocols

/**
 Wrapper for `FBSDKCoreKit.AppLinkResolving`

 - SeeAlso: `FBSDKCoreKit.AppLinkResolving`
 */
public typealias AppLinkResolving = FBSDKCoreKit.AppLinkResolving

/**
 Wrapper for `FBSDKCoreKit.AppLinkReturnToRefererControllerDelegate`

 - SeeAlso: `FBSDKCoreKit.AppLinkReturnToRefererControllerDelegate`
 */
public typealias AppLinkReturnToRefererControllerDelegate = FBSDKCoreKit.AppLinkReturnToRefererControllerDelegate

/**
 Wrapper for `FBSDKCoreKit.AppLinkReturnToRefererViewDelegate`

 - SeeAlso: `FBSDKCoreKit.AppLinkReturnToRefererViewDelegate`
 */
public typealias AppLinkReturnToRefererViewDelegate = FBSDKCoreKit.AppLinkReturnToRefererViewDelegate

/**
 Wrapper for `FBSDKCoreKit.Copying`

 - SeeAlso: `FBSDKCoreKit.Copying`
 */
public typealias Copying = FBSDKCoreKit.Copying

/**
 Wrapper for `FBSDKCoreKit.GraphErrorRecoveryProcessorDelegate`

 - SeeAlso: `FBSDKCoreKit.GraphErrorRecoveryProcessorDelegate`
 */
public typealias GraphErrorRecoveryProcessorDelegate = FBSDKCoreKit.GraphErrorRecoveryProcessorDelegate

/**
 Wrapper for `FBSDKCoreKit.GraphRequestConnectionDelegate`

 - SeeAlso: `FBSDKCoreKit.GraphRequestConnectionDelegate`
 */
public typealias GraphRequestConnectionDelegate = FBSDKCoreKit.GraphRequestConnectionDelegate

/**
 Wrapper for `FBSDKCoreKit.MutableCopying`

 - SeeAlso: `FBSDKCoreKit.MutableCopying`
 */
public typealias MutableCopying = FBSDKCoreKit.MutableCopying
