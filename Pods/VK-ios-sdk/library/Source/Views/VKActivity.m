//
//  VKActivity.m
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

#import "VKActivity.h"
#import "VKBundle.h"
#import "VKShareDialogController.h"
#import "VKUtil.h"

NSString *const VKActivityTypePost = @"VKActivityTypePost";

@interface VKActivity ()
@property(nonatomic, strong) VKShareDialogController *shareDialog;
@end

@implementation VKActivity
+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

+ (BOOL)vkShareExtensionEnabled {
    return [VKUtil isOperatingSystemAtLeastIOS8] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"vk-share://extension"]];
}

- (NSString *)activityType {
    return VKActivityTypePost;
}

- (UIImage *)activityImage {
    if (![VKUtil isOperatingSystemAtLeastIOS8])
        return VKImageNamed(@"ic_vk_ios7_activity_logo");

    return VKImageNamed(@"ic_vk_activity_logo");
}

- (NSString *)activityTitle {
    return VKLocalizedString(@"VK");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[UIImage class]]) return YES;
        else if ([item isKindOfClass:[NSString class]]) return YES;
        else if ([item isKindOfClass:[NSURL class]]) return YES;
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    self.shareDialog = [VKShareDialogController new];
    NSMutableArray *uploadImages = [NSMutableArray new];
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSString class]]) {
            self.shareDialog.text = item;
        } else if ([item isKindOfClass:[NSAttributedString class]]) {
            self.shareDialog.text = [(NSAttributedString *) item string];
        } else if ([item isKindOfClass:[UIImage class]]) {
            [uploadImages addObject:[VKUploadImage uploadImageWithImage:item andParams:[VKImageParameters jpegImageWithQuality:0.95]]];
        } else if ([item isKindOfClass:[NSURL class]]) {
            self.shareDialog.shareLink = [[VKShareLink alloc] initWithTitle:nil link:item];
        }
    }
    self.shareDialog.uploadImages = uploadImages;
    __weak __typeof(self) wself = self;
    [self.shareDialog setCompletionHandler:^(VKShareDialogController *dialog, VKShareDialogControllerResult result) {
        __strong __typeof(wself) sself = wself;
        [sself activityDidFinish:result == VKShareDialogControllerResultDone];
        sself.shareDialog = nil;
    }];
}

- (UIViewController *)activityViewController {
    return self.shareDialog;
}
@end
