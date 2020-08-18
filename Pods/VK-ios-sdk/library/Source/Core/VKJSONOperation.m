//
//  VKJSONOperation.m
//  VKSdk
//
//  Created by Roman Truba on 26.06.15.
//  Copyright (c) 2015 VK. All rights reserved.
//

#import "VKJSONOperation.h"

@implementation VKJSONOperation
- (void)setCompletionBlockWithSuccess:(void (^)(VKHTTPOperation *operation, id responseObject))success
                              failure:(void (^)(VKHTTPOperation *operation, NSError *error))failure {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
#pragma clang diagnostic ignored "-Wgnu"
    self.completionBlock = ^{
        id response = [self responseJson];
        if (self.error) {
            if (failure) {
                dispatch_async(self.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
                    failure(self, self.error);
                });
            }
        }
        else {
            if (success) {
                dispatch_async(self.successCallbackQueue ?: dispatch_get_main_queue(), ^{
                    success(self, response);
                });
            }
        }
    };
#pragma clang diagnostic pop
}
@end
