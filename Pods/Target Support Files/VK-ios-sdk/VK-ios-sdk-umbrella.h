#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "VKApiBase.h"
#import "VKApiCaptcha.h"
#import "VKApiConst.h"
#import "VKApiDocs.h"
#import "VKApiFriends.h"
#import "VKApiGroups.h"
#import "VKApiModels.h"
#import "VKApiPhotos.h"
#import "VKApiUsers.h"
#import "VKApiWall.h"
#import "VKApiObject.h"
#import "VKApiObjectArray.h"
#import "VKAudio.h"
#import "VKCounters.h"
#import "VKDocs.h"
#import "VKGroup.h"
#import "VKLikes.h"
#import "VKPhoto.h"
#import "VKPhotoSize.h"
#import "VKRelative.h"
#import "VKSchool.h"
#import "VKUniversity.h"
#import "VKUser.h"
#import "VKUploadMessagesPhotoRequest.h"
#import "VKUploadPhotoBase.h"
#import "VKUploadPhotoRequest.h"
#import "VKUploadWallPhotoRequest.h"
#import "VKApi.h"
#import "NSError+VKError.h"
#import "VKError.h"
#import "VKHTTPClient.h"
#import "VKHTTPOperation.h"
#import "VKJSONOperation.h"
#import "VKObject.h"
#import "VKOperation.h"
#import "VKRequest.h"
#import "VKRequestsScheduler.h"
#import "VKResponse.h"
#import "VKImageParameters.h"
#import "VKUploadImage.h"
#import "NSString+MD5.h"
#import "OrderedDictionary.h"
#import "VKUtil.h"
#import "VKActivity.h"
#import "VKAuthorizeController.h"
#import "VKCaptchaView.h"
#import "VKCaptchaViewController.h"
#import "VKShareDialogController.h"
#import "VKSharedTransitioningObject.h"
#import "VKAccessToken.h"
#import "VKAuthorizationResult.h"
#import "VKBatchRequest.h"
#import "VKBundle.h"
#import "VKPermissions.h"
#import "VKSdk.h"
#import "VKSdkVersion.h"

FOUNDATION_EXPORT double VK_ios_sdkVersionNumber;
FOUNDATION_EXPORT const unsigned char VK_ios_sdkVersionString[];

