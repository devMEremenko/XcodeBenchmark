//
//  VKShareDialogController.h
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
#import "VKObject.h"
#import "VKUploadImage.h"


typedef NS_ENUM(NSInteger, VKShareDialogControllerResult) {
    VKShareDialogControllerResultCancelled,
    VKShareDialogControllerResultDone
};

/*
 * Link representation for share dialog
 */
@interface VKShareLink : VKObject
/// Use that field for present link description in share dialog interface
@property(nonatomic, copy) NSString *title;
/// Use that field for pass real link to VK. Host of the link will be displayed in share dialog
@property(nonatomic, copy) NSURL *link;

- (instancetype)initWithTitle:(NSString *)title link:(NSURL *)link;
@end


/**
* Creates dialog for sharing some information from your app to user wall in VK
*/
@interface VKShareDialogController : UIViewController
/// Array of prepared VKUploadImage objects for upload and share. User can remove any attachment
@property(nonatomic, strong) NSArray *uploadImages;

/// Photos already uploaded to VK. That is array of photos ids: @["ownerid_photoid", ...];
@property(nonatomic, strong) NSArray *vkImages;

/// Links attachment for new post
@property(nonatomic, strong) VKShareLink *shareLink;

/// Text to share. User can change it
@property(nonatomic, copy) NSString *text;

/// Put only needed scopes into that array. By default equals @[VK_PER_WALL,VK_PER_PHOTOS]
@property(nonatomic, strong) NSArray *requestedScope;

/// You can receive information about sharing state
@property(nonatomic, copy) void (^completionHandler)(VKShareDialogController *dialog, VKShareDialogControllerResult result);

/// Flag meaning the share viewcontroller manage it's presentation state by itself
@property(nonatomic, assign) BOOL dismissAutomatically;

/// Contains post id created via share dialog. Example string: 123_4567890
@property(nonatomic, readonly, copy) NSString *postId;

@end
