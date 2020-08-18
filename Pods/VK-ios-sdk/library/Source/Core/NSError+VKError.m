//
//  NSError+VKError.m
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

#import "NSError+VKError.h"

NSString *const VKSdkErrorDomain = @"VKSdkErrorDomain";
NSString *const VkErrorDescriptionKey = @"VkErrorDescriptionKey";

@implementation NSError (VKError)

+ (NSError *)errorWithVkError:(VKError *)vkError {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    NSInteger originalCode = vkError.errorCode;
    if (vkError.apiError) {
        vkError = vkError.apiError;
    }
    if (originalCode == VK_API_CANCELED) {
        originalCode = NSURLErrorCancelled;
    }
    userInfo[NSLocalizedDescriptionKey] = vkError.errorMessage ? vkError.errorMessage : NSLocalizedStringFromTable(@"Something went wrong", nil, @"");
    userInfo[VkErrorDescriptionKey] = vkError;

    return [[NSError alloc] initWithDomain:VKSdkErrorDomain code:originalCode userInfo:userInfo];
}

- (NSError *)copyWithVkError:(VKError *)vkError {
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy];
    userInfo[VkErrorDescriptionKey] = vkError;

    return [[NSError alloc] initWithDomain:self.domain code:self.code userInfo:userInfo];
}

- (VKError *)vkError {
    return (VKError *) self.userInfo[VkErrorDescriptionKey];
}

@end
