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

import FBSDKLoginKit
import Foundation

// Typealiases for FBSDKLoginKit types to avoid having to import
// dependent libraries. At somepoint these will be likely
// become "wrapper" types that extend and enhance functionality
// in addition to exposing it. For now it suffices to simply expose
// them to the correct library aka. FacebookLogin

// MARK: - Classes

/**
 Wrapper for `FBSDKLoginKit.AccessToken`

 - SeeAlso: `FBSDKLoginKit.AccessToken`
 */
public typealias AccessToken = FBSDKLoginKit.AccessToken

/**
 Wrapper for `FBSDKLoginKit.DefaultAudience`

 - SeeAlso: `FBSDKLoginKit.DefaultAudience`
 */
public typealias DefaultAudience = FBSDKLoginKit.DefaultAudience

/**
 Wrapper for `FBSDKLoginKit.DeviceLoginCodeInfo`

 - SeeAlso: `FBSDKLoginKit.DeviceLoginCodeInfo`
 */
public typealias DeviceLoginCodeInfo = FBSDKLoginKit.DeviceLoginCodeInfo

/**
 Wrapper for `FBSDKLoginKit.DeviceLoginError`

 - SeeAlso: `FBSDKLoginKit.DeviceLoginError`
 */
public typealias DeviceLoginError = FBSDKLoginKit.DeviceLoginError

/**
 Wrapper for `FBSDKLoginKit.DeviceLoginManager`

 - SeeAlso: `FBSDKLoginKit.DeviceLoginManager`
 */
public typealias DeviceLoginManager = FBSDKLoginKit.DeviceLoginManager

/**
 Wrapper for `FBSDKLoginKit.DeviceLoginManagerResult`

 - SeeAlso: `FBSDKLoginKit.DeviceLoginManagerResult`
 */
public typealias DeviceLoginManagerResult = FBSDKLoginKit.DeviceLoginManagerResult

/**
 Wrapper for `FBSDKLoginKit.FBButton`

 - SeeAlso: `FBSDKLoginKit.FBButton`
 */
public typealias FBButton = FBSDKLoginKit.FBButton

/**
 Wrapper for `FBSDKLoginKit.FBLoginButton`

 - SeeAlso: `FBSDKLoginKit.FBLoginButton`
 */
public typealias FBLoginButton = FBSDKLoginKit.FBLoginButton

/**
 Wrapper for `FBSDKLoginKit.FBLoginTooltipView`

 - SeeAlso: `FBSDKLoginKit.FBLoginTooltipView`
 */
public typealias FBLoginTooltipView = FBSDKLoginKit.FBLoginTooltipView

/**
 Wrapper for `FBSDKLoginKit.FBTooltipView`

 - SeeAlso: `FBSDKLoginKit.FBTooltipView`
 */
public typealias FBTooltipView = FBSDKLoginKit.FBTooltipView

/**
 Wrapper for `FBSDKLoginKit.GraphRequestConnection`

 - SeeAlso: `FBSDKLoginKit.GraphRequestConnection`
 */
public typealias GraphRequestConnection = FBSDKLoginKit.GraphRequestConnection

/**
 Wrapper for `FBSDKLoginKit.LoginAuthType`

 - SeeAlso: `FBSDKLoginKit.LoginAuthType`
 */
public typealias LoginAuthType = FBSDKLoginKit.LoginAuthType

/**
 Wrapper for `FBSDKLoginKit.LoginBehavior`

 - SeeAlso: `FBSDKLoginKit.LoginBehavior`
 */
public typealias LoginBehavior = FBSDKLoginKit.LoginBehavior

/**
 Wrapper for `FBSDKLoginKit.LoginError`

 - SeeAlso: `FBSDKLoginKit.LoginError`
 */
public typealias LoginError = FBSDKLoginKit.LoginError

/**
 Wrapper for `FBSDKLoginKit.LoginManager`

 - SeeAlso: `FBSDKLoginKit.LoginManager`
 */
public typealias LoginManager = FBSDKLoginKit.LoginManager

/**
 Wrapper for `FBSDKLoginKit.LoginManagerLoginResult`

 - SeeAlso: `FBSDKLoginKit.LoginManagerLoginResult`
 */
public typealias LoginManagerLoginResult = FBSDKLoginKit.LoginManagerLoginResult

/**
 Wrapper for `FBSDKLoginKit.LoginManagerLoginResultBlock`

 - SeeAlso: `FBSDKLoginKit.LoginManagerLoginResultBlock`
 */
public typealias LoginManagerLoginResultBlock = FBSDKLoginKit.LoginManagerLoginResultBlock

// MARK: - Protocols

/**
 Wrapper for `FBSDKLoginKit.Copying`

 - SeeAlso: `FBSDKLoginKit.Copying`
 */
public typealias Copying = FBSDKLoginKit.Copying

/**
 Wrapper for `FBSDKLoginKit.DeviceLoginManagerDelegate`

 - SeeAlso: `FBSDKLoginKit.DeviceLoginManagerDelegate`
 */
public typealias DeviceLoginManagerDelegate = FBSDKLoginKit.DeviceLoginManagerDelegate

/**
 Wrapper for `FBSDKLoginKit.GraphRequestConnectionDelegate`

 - SeeAlso: `FBSDKLoginKit.GraphRequestConnectionDelegate`
 */
public typealias GraphRequestConnectionDelegate = FBSDKLoginKit.GraphRequestConnectionDelegate

/**
 Wrapper for `FBSDKLoginKit.LoginButtonDelegate`

 - SeeAlso: `FBSDKLoginKit.LoginButtonDelegate`
 */
public typealias LoginButtonDelegate = FBSDKLoginKit.LoginButtonDelegate

/**
 Wrapper for `FBSDKLoginKit.LoginTooltipViewDelegate`

 - SeeAlso: `FBSDKLoginKit.LoginTooltipViewDelegate`
 */
public typealias LoginTooltipViewDelegate = FBSDKLoginKit.LoginTooltipViewDelegate
