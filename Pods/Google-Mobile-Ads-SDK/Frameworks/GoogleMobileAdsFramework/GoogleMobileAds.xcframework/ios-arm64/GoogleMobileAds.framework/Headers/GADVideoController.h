//
//  GADVideoController.h
//  Google Mobile Ads SDK
//
//  Copyright 2016 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAdsDefines.h>
#import <UIKit/UIKit.h>

@protocol GADVideoControllerDelegate;

/// The video controller class provides a way to get the video metadata and also manages video
/// content of the ad rendered by the Google Mobile Ads SDK. You don't need to create an instance of
/// this class. When the ad rendered by the Google Mobile Ads SDK loads video content, you may be
/// able to get an instance of this class from the rendered ad object.
@interface GADVideoController : NSObject

/// Delegate for receiving video notifications.
@property(nonatomic, weak, nullable) id<GADVideoControllerDelegate> delegate;

/// Indicates whether the video is muted.
@property(nonatomic, readonly) BOOL isMuted;

/// Mute or unmute video. Set to YES to mute the video. Set to NO to allow the video to play sound.
/// Doesn't do anything if -customControlsEnabled returns NO.
- (void)setMute:(BOOL)mute;

/// Play the video. Doesn't do anything if the video is already playing or if
/// -customControlsEnabled returns NO.
- (void)play;

/// Pause the video. Doesn't do anything if the video is already paused or if
/// -customControlsEnabled- returns NO.
- (void)pause;

/// Stops the video and displays the video's first frame. Call -play to resume playback at the start
/// of the video. Doesn't do anything if -customControlsEnabled returns NO.
- (void)stop;

/// Indicates whether video custom controls (for example, play/pause/mute/unmute) are enabled.
- (BOOL)customControlsEnabled;

/// Indicates whether video click to expand behavior is enabled.
- (BOOL)clickToExpandEnabled;

@end
