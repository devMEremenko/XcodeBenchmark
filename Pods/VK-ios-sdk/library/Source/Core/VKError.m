//
//  VKError.m
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

#import "VKError.h"
#import "VKRequest.h"

@implementation VKError
+ (instancetype)errorWithCode:(NSInteger)errorCode {
    VKError *error = [VKError new];
    error.errorCode = errorCode;
    return error;
}

+ (instancetype)errorWithJson:(id)JSON {
    VKError *internalError = [VKError new];
    internalError.errorCode = [JSON[VK_API_ERROR_CODE] intValue];
    internalError.errorMessage = JSON[VK_API_ERROR_MSG];
    internalError.errorText = JSON[VK_API_ERROR_TEXT];
    internalError.requestParams = JSON[VK_API_REQUEST_PARAMS];
    internalError.json = JSON;
    if (internalError.errorCode == 14) {
        internalError.captchaImg = JSON[VK_API_CAPTCHA_IMG];
        internalError.captchaSid = JSON[VK_API_CAPTCHA_SID];
    }
    if (internalError.errorCode == 17) {
        internalError.redirectUri = JSON[VK_API_REDIRECT_URI];
    }

    VKError *mainError = [VKError errorWithCode:VK_API_ERROR];
    mainError.apiError = internalError;
    mainError.json = JSON;
    return mainError;
}

+ (instancetype)errorWithQuery:(NSDictionary *)queryParams {
    VKError *error = [VKError new];
    error.errorCode = VK_API_ERROR;
    error.errorReason = queryParams[@"error_reason"];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    error.errorMessage = [queryParams[@"error_description"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#else 
    error.errorMessage = [queryParams[@"error_description"] stringByRemovingPercentEncoding];
#endif
    return error;
}

- (void)answerCaptcha:(NSString *)userEnteredCode {
    [self.request addExtraParameters:@{VK_API_CAPTCHA_SID : self.captchaSid, VK_API_CAPTCHA_KEY : userEnteredCode}];
    [self.request repeat];
}

- (NSString *)description {
    if (self.httpError) {
        return [NSString stringWithFormat:@"<VKError: %p; HTTP error {%@}>", self, self.httpError];
    }
    else {
        if (self.errorCode == VK_API_ERROR)
            return [NSString stringWithFormat:@"<VKError: %p; Internal API error (%@, %@, %@})>",
                                              self, self.apiError, self.errorReason, self.errorMessage];
        else if (self.errorCode == VK_API_CANCELED)
            return [NSString stringWithFormat:@"<VKError: %p; SDK error (request canceled)>", self];
        else if (self.errorCode == VK_API_REQUEST_NOT_PREPARED)
            return [NSString stringWithFormat:@"<VKError: %p; SDK error (request not prepared)>", self];
        return [NSString stringWithFormat:@"<VKError: %p; API error {code: %ld; message: %@;}>", self, (long) self.errorCode, self.errorMessage];
    }
//    return [NSString stringWithFormat:@"<VKError: %p;>", self];
}

@end
