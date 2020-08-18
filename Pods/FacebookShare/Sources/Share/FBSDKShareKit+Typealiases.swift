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

// swiftlint:disable type_name file_length

import FBSDKShareKit
import Foundation

// Typealiases for FBSDKShareKit types to avoid having to import
// dependent libraries. At somepoint these will be likely
// become "wrapper" types that extend and enhance functionality
// in addition to exposing it. For now it suffices to simply expose
// them to the correct library aka. FacebookShare

// MARK: - Classes

/**
 Wrapper for `FBSDKShareKit.AppGroupContent`

 - SeeAlso: `FBSDKShareKit.AppGroupContent`
 */
public typealias AppGroupContent = FBSDKShareKit.AppGroupContent

/**
 Wrapper for `FBSDKShareKit.AppGroupPrivacy`

 - SeeAlso: `FBSDKShareKit.AppGroupPrivacy`
 */
public typealias AppGroupPrivacy = FBSDKShareKit.AppGroupPrivacy

/**
 Wrapper for `FBSDKShareKit.AppInviteContent`

 - SeeAlso: `FBSDKShareKit.AppInviteContent`
 */
public typealias AppInviteContent = FBSDKShareKit.AppInviteContent

/**
 Wrapper for `FBSDKShareKit.AppInviteDestination`

 - SeeAlso: `FBSDKShareKit.AppInviteDestination`
 */
public typealias AppInviteDestination = FBSDKShareKit.AppInviteDestination

/**
 Wrapper for `FBSDKShareKit.CameraEffectArguments`

 - SeeAlso: `FBSDKShareKit.CameraEffectArguments`
 */
public typealias CameraEffectArguments = FBSDKShareKit.CameraEffectArguments

/**
 Wrapper for `FBSDKShareKit.CameraEffectTextures`

 - SeeAlso: `FBSDKShareKit.CameraEffectTextures`
 */
public typealias CameraEffectTextures = FBSDKShareKit.CameraEffectTextures

/**
 Wrapper for `FBSDKShareKit.FBButton`

 - SeeAlso: `FBSDKShareKit.FBButton`
 */
public typealias FBButton = FBSDKShareKit.FBButton

/**
 Wrapper for `FBSDKShareKit.FBSendButton`

 - SeeAlso: `FBSDKShareKit.FBSendButton`
 */
public typealias FBSendButton = FBSDKShareKit.FBSendButton

/**
 Wrapper for `FBSDKShareKit.FBShareButton`

 - SeeAlso: `FBSDKShareKit.FBShareButton`
 */
public typealias FBShareButton = FBSDKShareKit.FBShareButton

/**
 Wrapper for `FBSDKShareKit.GameRequestActionType`

 - SeeAlso: `FBSDKShareKit.GameRequestActionType`
 */
public typealias GameRequestActionType = FBSDKShareKit.GameRequestActionType

/**
 Wrapper for `FBSDKShareKit.GameRequestContent`

 - SeeAlso: `FBSDKShareKit.GameRequestContent`
 */
public typealias GameRequestContent = FBSDKShareKit.GameRequestContent

/**
 Wrapper for `FBSDKShareKit.GameRequestDialog`

 - SeeAlso: `FBSDKShareKit.GameRequestDialog`
 */
public typealias GameRequestDialog = FBSDKShareKit.GameRequestDialog

/**
 Wrapper for `FBSDKShareKit.GameRequestFilter`

 - SeeAlso: `FBSDKShareKit.GameRequestFilter`
 */
public typealias GameRequestFilter = FBSDKShareKit.GameRequestFilter

/**
 Wrapper for `FBSDKShareKit.GraphRequestConnection`

 - SeeAlso: `FBSDKShareKit.GraphRequestConnection`
 */
public typealias GraphRequestConnection = FBSDKShareKit.GraphRequestConnection

/**
 Wrapper for `FBSDKShareKit.Hashtag`

 - SeeAlso: `FBSDKShareKit.Hashtag`
 */
public typealias Hashtag = FBSDKShareKit.Hashtag

/**
 Wrapper for `FBSDKShareKit.LikeObjectType`

 - SeeAlso: `FBSDKShareKit.LikeObjectType`
 */
public typealias LikeObjectType = FBSDKShareKit.LikeObjectType

/**
 Wrapper for `FBSDKShareKit.MessageDialog`

 - SeeAlso: `FBSDKShareKit.MessageDialog`
 */
public typealias MessageDialog = FBSDKShareKit.MessageDialog

/**
 Wrapper for `FBSDKShareKit.PHAsset`

 - SeeAlso: `FBSDKShareKit.PHAsset`
 */
public typealias PHAsset = FBSDKShareKit.PHAsset

/**
 Wrapper for `FBSDKShareKit.ShareAPI`

 - SeeAlso: `FBSDKShareKit.ShareAPI`
 */
public typealias ShareAPI = FBSDKShareKit.ShareAPI

/**
 Wrapper for `FBSDKShareKit.ShareBridgeOptions`

 - SeeAlso: `FBSDKShareKit.ShareBridgeOptions`
 */
public typealias ShareBridgeOptions = FBSDKShareKit.ShareBridgeOptions

/**
 Wrapper for `FBSDKShareKit.ShareCameraEffectContent`

 - SeeAlso: `FBSDKShareKit.ShareCameraEffectContent`
 */
public typealias ShareCameraEffectContent = FBSDKShareKit.ShareCameraEffectContent

/**
 Wrapper for `FBSDKShareKit.ShareDialog`

 - SeeAlso: `FBSDKShareKit.ShareDialog`
 */
public typealias ShareDialog = FBSDKShareKit.ShareDialog

/**
 Wrapper for `FBSDKShareKit.ShareError`

 - SeeAlso: `FBSDKShareKit.ShareError`
 */
public typealias ShareError = FBSDKShareKit.ShareError

/**
 Wrapper for `FBSDKShareKit.ShareLinkContent`

 - SeeAlso: `FBSDKShareKit.ShareLinkContent`
 */
public typealias ShareLinkContent = FBSDKShareKit.ShareLinkContent

/**
 Wrapper for `FBSDKShareKit.ShareMediaContent`

 - SeeAlso: `FBSDKShareKit.ShareMediaContent`
 */
public typealias ShareMediaContent = FBSDKShareKit.ShareMediaContent

/**
 Wrapper for `FBSDKShareKit.ShareMessengerGenericTemplateContent`

 - SeeAlso: `FBSDKShareKit.ShareMessengerGenericTemplateContent`
 */
public typealias ShareMessengerGenericTemplateContent = FBSDKShareKit.ShareMessengerGenericTemplateContent

/**
 Wrapper for `FBSDKShareKit.ShareMessengerGenericTemplateElement`

 - SeeAlso: `FBSDKShareKit.ShareMessengerGenericTemplateElement`
 */
public typealias ShareMessengerGenericTemplateElement = FBSDKShareKit.ShareMessengerGenericTemplateElement

/**
 Wrapper for `FBSDKShareKit.ShareMessengerGenericTemplateImageAspectRatio`

 - SeeAlso: `FBSDKShareKit.ShareMessengerGenericTemplateImageAspectRatio`
 */
public typealias ShareMessengerGenericTemplateImageAspectRatio =
  FBSDKShareKit.ShareMessengerGenericTemplateImageAspectRatio

/**
 Wrapper for `FBSDKShareKit.ShareMessengerMediaTemplateContent`

 - SeeAlso: `FBSDKShareKit.ShareMessengerMediaTemplateContent`
 */
public typealias ShareMessengerMediaTemplateContent = FBSDKShareKit.ShareMessengerMediaTemplateContent

/**
 Wrapper for `FBSDKShareKit.ShareMessengerMediaTemplateMediaType`

 - SeeAlso: `FBSDKShareKit.ShareMessengerMediaTemplateMediaType`
 */
public typealias ShareMessengerMediaTemplateMediaType = FBSDKShareKit.ShareMessengerMediaTemplateMediaType

/**
 Wrapper for `FBSDKShareKit.ShareMessengerOpenGraphMusicTemplateContent`

 - SeeAlso: `FBSDKShareKit.ShareMessengerOpenGraphMusicTemplateContent`
 */
public typealias ShareMessengerOpenGraphMusicTemplateContent = FBSDKShareKit.ShareMessengerOpenGraphMusicTemplateContent

/**
 Wrapper for `FBSDKShareKit.ShareMessengerURLActionButton`

 - SeeAlso: `FBSDKShareKit.ShareMessengerURLActionButton`
 */
public typealias ShareMessengerURLActionButton = FBSDKShareKit.ShareMessengerURLActionButton

/**
 Wrapper for `FBSDKShareKit.ShareOpenGraphAction`

 - SeeAlso: `FBSDKShareKit.ShareOpenGraphAction`
 */
public typealias ShareOpenGraphAction = FBSDKShareKit.ShareOpenGraphAction

/**
 Wrapper for `FBSDKShareKit.ShareOpenGraphContent`

 - SeeAlso: `FBSDKShareKit.ShareOpenGraphContent`
 */
public typealias ShareOpenGraphContent = FBSDKShareKit.ShareOpenGraphContent

/**
 Wrapper for `FBSDKShareKit.ShareOpenGraphObject`

 - SeeAlso: `FBSDKShareKit.ShareOpenGraphObject`
 */
public typealias ShareOpenGraphObject = FBSDKShareKit.ShareOpenGraphObject

/**
 Wrapper for `FBSDKShareKit.ShareOpenGraphValueContainer`

 - SeeAlso: `FBSDKShareKit.ShareOpenGraphValueContainer`
 */
public typealias ShareOpenGraphValueContainer = FBSDKShareKit.ShareOpenGraphValueContainer

/**
 Wrapper for `FBSDKShareKit.SharePhoto`

 - SeeAlso: `FBSDKShareKit.SharePhoto`
 */
public typealias SharePhoto = FBSDKShareKit.SharePhoto

/**
 Wrapper for `FBSDKShareKit.SharePhotoContent`

 - SeeAlso: `FBSDKShareKit.SharePhotoContent`
 */
public typealias SharePhotoContent = FBSDKShareKit.SharePhotoContent

/**
 Wrapper for `FBSDKShareKit.ShareVideo`

 - SeeAlso: `FBSDKShareKit.ShareVideo`
 */
public typealias ShareVideo = FBSDKShareKit.ShareVideo

/**
 Wrapper for `FBSDKShareKit.ShareVideoContent`

 - SeeAlso: `FBSDKShareKit.ShareVideoContent`
 */
public typealias ShareVideoContent = FBSDKShareKit.ShareVideoContent

// MARK: - Protocols

/**
 Wrapper for `FBSDKShareKit.Copying`

 - SeeAlso: `FBSDKShareKit.Copying`
 */
public typealias Copying = FBSDKShareKit.Copying

/**
 Wrapper for `FBSDKShareKit.GameRequestDialogDelegate`

 - SeeAlso: `FBSDKShareKit.GameRequestDialogDelegate`
 */
public typealias GameRequestDialogDelegate = FBSDKShareKit.GameRequestDialogDelegate

/**
 Wrapper for `FBSDKShareKit.GraphRequestConnectionDelegate`

 - SeeAlso: `FBSDKShareKit.GraphRequestConnectionDelegate`
 */
public typealias GraphRequestConnectionDelegate = FBSDKShareKit.GraphRequestConnectionDelegate

/**
 Wrapper for `FBSDKShareKit.Liking`

 - SeeAlso: `FBSDKShareKit.Liking`
 */
public typealias Liking = FBSDKShareKit.Liking

/**
 Wrapper for `FBSDKShareKit.ShareMedia`

 - SeeAlso: `FBSDKShareKit.ShareMedia`
 */
public typealias ShareMedia = FBSDKShareKit.ShareMedia

/**
 Wrapper for `FBSDKShareKit.ShareMessengerActionButton`

 - SeeAlso: `FBSDKShareKit.ShareMessengerActionButton`
 */
public typealias ShareMessengerActionButton = FBSDKShareKit.ShareMessengerActionButton

/**
 Wrapper for `FBSDKShareKit.ShareOpenGraphValueContaining`

 - SeeAlso: `FBSDKShareKit.ShareOpenGraphValueContaining`
 */
public typealias ShareOpenGraphValueContaining = FBSDKShareKit.ShareOpenGraphValueContaining

/**
 Wrapper for `FBSDKShareKit.Sharing`

 - SeeAlso: `FBSDKShareKit.Sharing`
 */
public typealias Sharing = FBSDKShareKit.Sharing

/**
 Wrapper for `FBSDKShareKit.SharingButton`

 - SeeAlso: `FBSDKShareKit.SharingButton`
 */
public typealias SharingButton = FBSDKShareKit.SharingButton

/**
 Wrapper for `FBSDKShareKit.SharingContent`

 - SeeAlso: `FBSDKShareKit.SharingContent`
 */
public typealias SharingContent = FBSDKShareKit.SharingContent

/**
 Wrapper for `FBSDKShareKit.SharingDelegate`

 - SeeAlso: `FBSDKShareKit.SharingDelegate`
 */
public typealias SharingDelegate = FBSDKShareKit.SharingDelegate

/**
 Wrapper for `FBSDKShareKit.SharingDialog`

 - SeeAlso: `FBSDKShareKit.SharingDialog`
 */
public typealias SharingDialog = FBSDKShareKit.SharingDialog

/**
 Wrapper for `FBSDKShareKit.SharingScheme`

 - SeeAlso: `FBSDKShareKit.SharingScheme`
 */
public typealias SharingScheme = FBSDKShareKit.SharingScheme

/**
 Wrapper for `FBSDKShareKit.SharingValidation`

 - SeeAlso: `FBSDKShareKit.SharingValidation`
 */
public typealias SharingValidation = FBSDKShareKit.SharingValidation
