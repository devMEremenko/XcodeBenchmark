//
//  VKCaptchaView.m
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

#import "VKCaptchaView.h"
#import "VKUtil.h"
#import "VKHTTPClient.h"
#import "VKHTTPOperation.h"

@interface VKCaptchaView () <UITextFieldDelegate> {
    VKError *_error;
    UIImageView *_captchaImage;
    UILabel *_infoLabel;
    UITextField *_captchaTextField;
    UIButton *_doneButton;
    UIActivityIndicatorView *_imageLoadingActivity;
}
@end

CGFloat kCaptchaImageWidth = 240;
CGFloat kCaptchaImageHeight = 96;
CGFloat kCaptchaViewHeight = 138;

@implementation VKCaptchaView
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame andError:(VKError *)captchaError {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self setBackgroundColor:VK_COLOR];

        _error = captchaError;

        _imageLoadingActivity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.bounds.size.width - 30) / 2, 40, 30, 30)];
        _imageLoadingActivity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _imageLoadingActivity.hidesWhenStopped = YES;
        _imageLoadingActivity.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_imageLoadingActivity];
        [_imageLoadingActivity startAnimating];

        _captchaImage = [[UIImageView alloc] init];
        _captchaImage.contentMode = UIViewContentModeScaleAspectFit;
        _captchaImage.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_captchaImage];

        _captchaTextField = [[UITextField alloc] init];
        _captchaTextField.delegate = self;
        _captchaTextField.borderStyle = UITextBorderStyleNone;
        _captchaTextField.textAlignment = NSTextAlignmentCenter;
        _captchaTextField.returnKeyType = UIReturnKeyDone;
        _captchaTextField.backgroundColor = [UIColor whiteColor];
        _captchaTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _captchaTextField.placeholder = NSLocalizedString(@"Enter captcha text", @"");
        _captchaTextField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        [self addSubview:_captchaTextField];
        VKHTTPOperation *operation = [[VKHTTPOperation alloc] initWithURLRequest:[[VKHTTPClient getClient] requestWithMethod:@"GET" path:_error.captchaImg parameters:nil secure:NO]];
        [operation setCompletionBlockWithSuccess:^(VKHTTPOperation *operation, id responseObject) {
            [_captchaImage setImage:[UIImage imageWithData:operation.responseData]];
        }                                failure:^(VKHTTPOperation *operation, NSError *error) {
        }];
        [[VKHTTPClient getClient] enqueueOperation:operation];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [self deviceDidRotate:nil];
    }
    return self;
}

- (void)deviceDidRotate:(NSNotification *)notification {
    [UIView animateWithDuration:notification ? 0.3 : 0 animations:^{
        _captchaImage.frame = CGRectMake((self.bounds.size.width - kCaptchaImageWidth) / 2, 5, kCaptchaImageWidth, kCaptchaImageHeight);
        _captchaTextField.frame = CGRectMake(_captchaImage.frame.origin.x, _captchaImage.frame.origin.y + kCaptchaImageHeight + 10, kCaptchaImageWidth, kCaptchaViewHeight - kCaptchaImageHeight - 10);
    }];
}

- (void)doneButtonPressed:(UIButton *)sender {
    [_error answerCaptcha:_captchaTextField.text];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:VKCaptchaAnsweredEvent object:nil];
}

- (void)didMoveToSuperview {
    [_captchaTextField becomeFirstResponder];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _captchaTextField) {
        [self doneButtonPressed:_doneButton];
        [textField endEditing:YES];
        return NO;
    }
    return YES;
}

@end
