//
//  VKError.h
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

#import <Foundation/Foundation.h>
#import "VKObject.h"
#import "VKApiConst.h"

static int const VK_API_ERROR = -101;
static int const VK_API_CANCELED = -102;
static int const VK_API_REQUEST_NOT_PREPARED = -103;
static int const VK_RESPONSE_STRING_PARSING_ERROR = -104;
static int const VK_AUTHORIZE_CONTROLLER_CANCEL = -105;

@class VKRequest;

/**
Class for presenting VK SDK and VK API errors
*/
@interface VKError : VKObject
/// Contains system HTTP error
@property(nonatomic, strong) NSError *httpError;
/// Describes API error
@property(nonatomic, strong) VKError *apiError;
/// Request which caused error
@property(nonatomic, strong) VKRequest *request;

/// May contains such errors:\n <b>HTTP status code</b> if HTTP error occured;\n <b>VK_API_ERROR</b> if API error occured;\n <b>VK_API_CANCELED</b> if request was canceled;\n <b>VK_API_REQUEST_NOT_PREPARED</b> if error occured while preparing request;
@property(nonatomic, assign) NSInteger errorCode;
/// API error message
@property(nonatomic, strong) NSString *errorMessage;
/// Reason for authorization fail
@property(nonatomic, strong) NSString *errorReason;
// Localized error text from server if there is one
@property(nonatomic, strong) NSString *errorText;
/// API parameters passed to request
@property(nonatomic, strong) NSDictionary *requestParams;
/// Captcha identifier for captcha-check
@property(nonatomic, strong) NSString *captchaSid;
/// Image for captcha-check
@property(nonatomic, strong) NSString *captchaImg;
/// Redirection address if validation check required
@property(nonatomic, strong) NSString *redirectUri;

@property(nonatomic, strong) id json;

/**
Generate new error with code
@param errorCode positive if it's an HTTP error. Negative if it's API or SDK error
*/
+ (instancetype)errorWithCode:(NSInteger)errorCode;

/**
Generate API error from JSON
@param JSON Json description of VK API error
*/
+ (instancetype)errorWithJson:(id)JSON;

/**
Generate API error from HTTP-query
@param queryParams key-value parameters
*/
+ (instancetype)errorWithQuery:(NSDictionary *)queryParams;

/**
Repeats failed captcha request with user entered answer to captcha
@param userEnteredCode answer for captcha
*/
- (void)answerCaptcha:(NSString *)userEnteredCode;
@end
