//
//  VKHttpClient.m
//
//  Based on AFNetworking library.
//  https://github.com/AFNetworking/AFNetworking
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

#import "VKHTTPClient.h"
#import "VKSdkVersion.h"
#import "VKImageParameters.h"
#import "VKUploadImage.h"
#import "VKUtil.h"

static VKHTTPClient *__clientInstance = nil;
static NSString const *VK_API_URI = @"api.vk.com/method/";
static NSString const *kVKMultipartFormBoundaryPrefix = @"VK_SDK";


@interface VKHTTPClient ()
@property(readwrite, nonatomic, strong) NSMutableDictionary *defaultHeaders;
@property(readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation VKHTTPClient
+ (instancetype)getClient {
    if (!__clientInstance)
        __clientInstance = [[VKHTTPClient alloc] init];
    return __clientInstance;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.defaultHeaders = [NSMutableDictionary dictionary];

    NSString *userAgent = nil;

    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f; VK SDK %@; %@)",
                                           [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *) kCFBundleExecutableKey] ?:
                                                   [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *) kCFBundleIdentifierKey],
                                           (__bridge id) CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?:
                                                   [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString *) kCFBundleVersionKey],
                                           [[UIDevice currentDevice] model],
                                           [[UIDevice currentDevice] systemVersion],
                                           ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f),
                    VK_SDK_VERSION,
                                           [[NSBundle mainBundle] bundleIdentifier]];

    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            CFStringTransform((__bridge CFMutableStringRef) (mutableUserAgent), NULL, kCFStringTransformToLatin, false);
            userAgent = mutableUserAgent;
        }
        [self setDefaultHeader:@"User-Agent" value:userAgent];
    }

    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    return self;
}

- (NSString *)defaultValueForHeader:(NSString *)header {
    return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value {
    [self.defaultHeaders setValue:value forKey:header];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                    secure:(BOOL)secure {
    NSParameterAssert(method);

    if (!path) {
        path = @"";
    }
    NSURL *apiUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http%@://%@", secure ? @"s" : @"", VK_API_URI]];
    NSURL *url = nil;
    if ([path hasPrefix:@"http"])
        url = [NSURL URLWithString:path];
    else
        url = [NSURL URLWithString:path relativeToURL:apiUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultHeaders];

    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", [VKUtil queryStringFromParams:parameters]]];
            [request setURL:url];
        }
        else {
            NSString *charset = (__bridge NSString *) CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[[VKUtil queryStringFromParams:parameters] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                                 images:(NSArray *)images {
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);

    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil secure:YES];
    NSString *formBoundary = [NSString stringWithFormat:@"%@.boundary.%08x%08x", kVKMultipartFormBoundaryPrefix, arc4random(), arc4random()];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", formBoundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];

    NSMutableData *postbody = [NSMutableData data];
    for (NSUInteger i = 0; i < images.count; i++) {
        VKUploadImage *uploadImageObject = images[i];
        NSString *fileName = [NSString stringWithFormat:@"file%d", (int) (i + 1)];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", formBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.%@\"\r\n", fileName, fileName, [uploadImageObject.parameters fileExtension]] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [uploadImageObject.parameters mimeType]] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:uploadImageObject.imageData];
    }
    [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", formBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postbody];
    return request;
}

- (void)enqueueOperation:(NSOperation *)operation {
    if (!operation) {
        return;
    }
    [self.operationQueue addOperation:operation];
}

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock {
    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
#if !OS_OBJECT_USE_OBJC
        dispatch_release(dispatchGroup);
#endif
    }];

    for (NSOperation *operation in operations) {
        void (^originalCompletionBlock)(void) = [operation.completionBlock copy];
        operation.completionBlock = ^{
            dispatch_queue_t queue = dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }

                NSUInteger numberOfFinishedOperations = [[operations indexesOfObjectsPassingTest:^BOOL(id op, NSUInteger __unused idx, BOOL __unused *stop) {
                    return [op isFinished];
                }] count];

                if (progressBlock) {
                    progressBlock(numberOfFinishedOperations, [operations count]);
                }

                dispatch_group_leave(dispatchGroup);
            });
        };

        dispatch_group_enter(dispatchGroup);
        [batchedOperation addDependency:operation];
    }
    [self.operationQueue addOperations:operations waitUntilFinished:NO];
    [self.operationQueue addOperation:batchedOperation];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.defaultHeaders forKey:@"defaultHeaders"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    self.defaultHeaders = [aDecoder decodeObjectForKey:@"defaultHeaders"];
    return self;
}

@end
