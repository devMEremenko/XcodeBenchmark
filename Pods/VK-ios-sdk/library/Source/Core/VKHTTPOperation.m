//
//  VKHTTPOperation.m
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

#import "VKHTTPOperation.h"
#import "VKRequest.h"
#import "NSError+VKError.h"

NSString *const VKNetworkingOperationFailingURLRequestErrorKey = @"VKNetworkingOperationFailingURLRequestErrorKey";
NSString *const VKNetworkingOperationFailingURLResponseErrorKey = @"VKNetworkingOperationFailingURLResponseErrorKey";
NSString *const VKNetworkingOperationDidStart = @"VKNetworkingOperationDidStart";

typedef void (^VKURLConnectionOperationProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@interface VKHTTPOperation ()
@property(readwrite, nonatomic, assign, getter = isCancelled) BOOL wasCanceled;
@property(readwrite, nonatomic, strong) NSRecursiveLock *lock;
@property(readwrite, nonatomic, strong) NSURLConnection *connection;
@property(readwrite, nonatomic, strong) NSURLRequest *request;
@property(readwrite, nonatomic, strong) NSHTTPURLResponse *response;
@property(readwrite, nonatomic, strong) NSError *error;
@property(readwrite, nonatomic, strong) NSData *responseData;
@property(readwrite, nonatomic, copy) NSString *responseString;
@property(readwrite, nonatomic, copy) id responseJson;
@property(readwrite, nonatomic, assign) NSStringEncoding responseStringEncoding;
@property(readwrite, nonatomic, assign) long long totalBytesRead;
@property(readwrite, nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property(readwrite, nonatomic, copy) VKURLConnectionOperationProgressBlock uploadProgress;
@property(readwrite, nonatomic, copy) VKURLConnectionOperationProgressBlock downloadProgress;
@property(readwrite, nonatomic, strong) NSError *HTTPError;
@property(nonatomic, strong) NSOutputStream *outputStream;
@property(readwrite, nonatomic, strong) NSError *JSONError;
@property(readwrite, nonatomic, weak) VKRequest *vkRequest;
@end

static void VKGetMediaTypeAndSubtypeWithString(NSString *string, NSString **type, NSString **subtype) {
    if (!string) {
        return;
    }

    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [scanner scanUpToString:@"/" intoString:type];
    [scanner scanString:@"/" intoString:nil];
    [scanner scanUpToString:@";" intoString:subtype];
}

@implementation VKHTTPOperation
@dynamic lock;

+ (instancetype)operationWithRequest:(VKRequest *)request {
    NSURLRequest *urlRequest = [request getPreparedRequest];

    if (!urlRequest)
        return nil;
    VKHTTPOperation *operation = [[[self class] alloc] initWithURLRequest:urlRequest];
    operation.vkRequest = request;
    return operation;
}

+ (void)networkRequestThreadEntryPoint:(id __unused)object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"VKSdkNetworking"];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });

    return _networkRequestThread;
}

- (id)initWithURLRequest:(NSURLRequest *)urlRequest {
    NSParameterAssert(urlRequest);

    self = [super init];
    if (!self) {
        return nil;
    }

    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = @"com.vk.networking.operation.lock";

    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];

    self.request = urlRequest;

    self.state = VKOperationReadyState;

    return self;
}

- (void)dealloc {
    if (_backgroundTaskIdentifier) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    if (_successCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
        dispatch_release(_successCallbackQueue);
#endif
        _successCallbackQueue = NULL;
    }

    if (_failureCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
        dispatch_release(_failureCallbackQueue);
#endif
        _failureCallbackQueue = NULL;
    }
}

//- (NSString *)description {
//    return [NSString stringWithFormat:@"<%@: %p, state: %@, cancelled: %@ request: %@, response: %@>", NSStringFromClass([self class]), self, AFKeyPathFromOperationState(self.state), ([self isCancelled] ? @"YES" : @"NO"), self.request, self.response];
//}
- (NSOutputStream *)outputStream {
    if (!_outputStream) {
        self.outputStream = [NSOutputStream outputStreamToMemory];
    }

    return _outputStream;
}

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    [self.lock lock];
    if (!self.backgroundTaskIdentifier) {
        UIApplication *application = [UIApplication sharedApplication];
        __weak __typeof(&*self) weakSelf = self;

        self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
            __strong __typeof(&*weakSelf) strongSelf = weakSelf;

            if (handler) {
                handler();
            }

            if (strongSelf) {
                [strongSelf cancel];

                [application endBackgroundTask:strongSelf.backgroundTaskIdentifier];
                strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    [self.lock unlock];
}

#endif

- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    self.uploadProgress = block;
}

- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block {
    self.downloadProgress = block;
}

- (NSString *)responseString {
    [self.lock lock];
    if (!_responseString && self.response && self.responseData) {
        _responseString = [[NSString alloc] initWithData:self.responseData encoding:self.responseStringEncoding];
        if (!_responseString) {
            VKError *vkError = [VKError errorWithCode:VK_RESPONSE_STRING_PARSING_ERROR];
            vkError.request = self.vkRequest;

            self.error = [NSError errorWithVkError:vkError];
        }
    }
    [self.lock unlock];

    return _responseString;
}

- (id)responseJson {
    [self.lock lock];
    if (!_responseJson && [self.responseData length] > 0 && [self isFinished] && !self.JSONError) {
        NSError *error = nil;

        // Workaround for behavior of Rails to return a single space for `head :ok` (a workaround for a bug in Safari), which is not interpreted as valid input by NSJSONSerialization.
        // See https://github.com/rails/rails/issues/1742
        if (self.responseString && ![self.responseString isEqualToString:@" "]) {
            // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
            // See http://stackoverflow.com/a/12843465/157142
            NSData *data = [self.responseString dataUsingEncoding:NSUTF8StringEncoding];

            if (data) {
                self.responseJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }
            else {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                [userInfo setValue:@"Operation responseData failed decoding as a UTF-8 string" forKey:NSLocalizedDescriptionKey];
                [userInfo setValue:[NSString stringWithFormat:@"Could not decode string: %@", self.responseString] forKey:NSLocalizedFailureReasonErrorKey];
                error = [[NSError alloc] initWithDomain:VKSdkErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
        }

        self.JSONError = error;
    }
    [self.lock unlock];

    return _responseJson;
}

- (NSStringEncoding)responseStringEncoding {
    // When no explicit charset parameter is provided by the sender, media subtypes of the "text" type are defined to have a default charset value of "ISO-8859-1" when received via HTTP. Data in character sets other than "ISO-8859-1" or its subsets MUST be labeled with an appropriate charset value.
    // See http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.4.1
    if (self.response && !self.response.textEncodingName && self.responseData && [self.response respondsToSelector:@selector(allHeaderFields)]) {
        NSString *type = nil;
        VKGetMediaTypeAndSubtypeWithString([[self.response allHeaderFields] valueForKey:@"Content-Type"], &type, nil);

        if ([type isEqualToString:@"text"]) {
            return NSISOLatin1StringEncoding;
        }
    }

    [self.lock lock];
    if (!_responseStringEncoding && self.response) {
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        if (self.response.textEncodingName) {
            CFStringEncoding IANAEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef) self.response.textEncodingName);
            if (IANAEncoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(IANAEncoding);
            }
        }

        self.responseStringEncoding = stringEncoding;
    }
    [self.lock unlock];

    return _responseStringEncoding;
}

- (void)pause {
    unsigned long long offset = 0;
    if ([self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey]) {
        offset = [[self.outputStream propertyForKey:NSStreamFileCurrentOffsetKey] unsignedLongLongValue];
    }
    else {
        offset = [[self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey] length];
    }

    NSMutableURLRequest *mutableURLRequest = [self.request mutableCopy];
    if ([self.response respondsToSelector:@selector(allHeaderFields)] && [[self.response allHeaderFields] valueForKey:@"ETag"]) {
        [mutableURLRequest setValue:[[self.response allHeaderFields] valueForKey:@"ETag"] forHTTPHeaderField:@"If-Range"];
    }
    [mutableURLRequest setValue:[NSString stringWithFormat:@"bytes=%llu-", offset] forHTTPHeaderField:@"Range"];
    self.request = mutableURLRequest;

    if ([self isPaused] || [self isFinished] || [self isCancelled]) {
        return;
    }

    [self.lock lock];

    if ([self isExecuting]) {
        [self.connection performSelector:@selector(cancel) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }

    self.state = VKOperationPausedState;

    [self.lock unlock];
}

- (BOOL)isPaused {
    return self.state == VKOperationPausedState;
}

- (void)resume {
    if (![self isPaused]) {
        return;
    }

    [self.lock lock];
    self.state = VKOperationReadyState;

    [self start];
    [self.lock unlock];
}

#pragma mark - NSOperation


- (void)start {
    [self.lock lock];
    if ([self isReady]) {
        self.state = VKOperationExecutingState;

        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)operationDidStart {
    [self.lock lock];
    [[NSNotificationCenter defaultCenter] postNotificationName:VKNetworkingOperationDidStart object:self];
    if (![self isCancelled]) {
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];

        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        for (NSString *runLoopMode in self.runLoopModes) {
            [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
        }

        [self.connection start];
    }
    [self.lock unlock];

    if ([self isCancelled]) {
        NSDictionary *userInfo = nil;
        if ([self.request URL]) {
            userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
        }
        self.error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];

        [self finish];
    }
}

- (void)finish {
    self.state = VKOperationFinishedState;
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];

        // Cancel the connection on the thread it runs on to prevent race conditions
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
}

- (void)cancelConnection {
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];

    if (![self isFinished] && self.connection) {
        [self.connection cancel];
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:error];
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)       connection:(NSURLConnection __unused *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.uploadProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.uploadProgress((NSUInteger) bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        });
    }
}

- (void)connection:(NSURLConnection __unused *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = (NSHTTPURLResponse *) response;

    [self.outputStream open];
}

- (void)connection:(NSURLConnection __unused *)connection
    didReceiveData:(NSData *)data {
    NSUInteger length = [data length];
    while (YES) {
        NSUInteger totalNumberOfBytesWritten = 0;
        if ([self.outputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *) [data bytes];

            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[0] maxLength:length];
                if (numberOfBytesWritten == -1) {
                    [self.connection cancel];
                    [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:self.outputStream.streamError];
                    return;
                }
                else {
                    totalNumberOfBytesWritten += numberOfBytesWritten;
                }
            }

            break;
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalBytesRead += length;

        if (self.downloadProgress) {
            self.downloadProgress(length, self.totalBytesRead, self.response.expectedContentLength);
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection __unused *)connection {
    self.responseData = [self.outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    [self.outputStream close];

    [self finish];

    self.connection = nil;
}

- (void)connection:(NSURLConnection __unused *)connection
  didFailWithError:(NSError *)error {
    self.error = error;

    [self.outputStream close];

    [self finish];

    self.connection = nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURLRequest *request = [aDecoder decodeObjectForKey:@"request"];

    self = [self initWithURLRequest:request];
    if (!self) {
        return nil;
    }

    self.state = (VKOperationState) [aDecoder decodeIntegerForKey:@"state"];
    self.wasCanceled = [aDecoder decodeBoolForKey:@"isCancelled"];
    self.response = [aDecoder decodeObjectForKey:@"response"];
    self.error = [aDecoder decodeObjectForKey:@"error"];
    self.responseData = [aDecoder decodeObjectForKey:@"responseData"];
    self.totalBytesRead = [[aDecoder decodeObjectForKey:@"totalBytesRead"] longLongValue];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self pause];

    [aCoder encodeObject:self.request forKey:@"request"];

    switch (self.state) {
        case VKOperationExecutingState:
        case VKOperationPausedState:
            [aCoder encodeInteger:VKOperationReadyState forKey:@"state"];
            break;

        default:
            [aCoder encodeInteger:self.state forKey:@"state"];
            break;
    }

    [aCoder encodeBool:[self isCancelled] forKey:@"isCancelled"];
    [aCoder encodeObject:self.response forKey:@"response"];
    [aCoder encodeObject:self.error forKey:@"error"];
    [aCoder encodeObject:self.responseData forKey:@"responseData"];
    [aCoder encodeObject:[NSNumber numberWithLongLong:self.totalBytesRead] forKey:@"totalBytesRead"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    VKHTTPOperation *operation = [(VKHTTPOperation *) [[self class] allocWithZone:zone] initWithURLRequest:self.request];

    operation.uploadProgress = self.uploadProgress;
    operation.downloadProgress = self.downloadProgress;

    return operation;
}

- (BOOL)hasAcceptableStatusCode {
    if (!self.response) {
        return NO;
    }

    NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger) [self.response statusCode] : 200;
    return statusCode == 200;
}

- (NSError *)error {
    [self.lock lock];
    if (!self.HTTPError && self.response) {
        if (![self hasAcceptableStatusCode]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:self.responseString forKey:NSLocalizedRecoverySuggestionErrorKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            [userInfo setValue:self.request forKey:VKNetworkingOperationFailingURLRequestErrorKey];
            [userInfo setValue:self.response forKey:VKNetworkingOperationFailingURLResponseErrorKey];

            if (![self hasAcceptableStatusCode]) {
                NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger) [self.response statusCode] : 200;
                [userInfo setValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Expected status code 200, got %d", @"AFNetworking", nil), statusCode] forKey:NSLocalizedDescriptionKey];
                self.HTTPError = [[NSError alloc] initWithDomain:VKSdkErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
            }
        }
    }
    [self.lock unlock];

    if (self.HTTPError) {
        return self.HTTPError;
    }
    return _error;
}

- (void)setSuccessCallbackQueue:(dispatch_queue_t)successCallbackQueue {
    if (successCallbackQueue != _successCallbackQueue) {
        if (_successCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_release(_successCallbackQueue);
#endif
            _successCallbackQueue = NULL;
        }

        if (successCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(successCallbackQueue);
#endif
            _successCallbackQueue = successCallbackQueue;
        }
    }
}

- (void)setFailureCallbackQueue:(dispatch_queue_t)failureCallbackQueue {
    if (failureCallbackQueue != _failureCallbackQueue) {
        if (_failureCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_release(_failureCallbackQueue);
#endif
            _failureCallbackQueue = NULL;
        }

        if (failureCallbackQueue) {
#if !OS_OBJECT_USE_OBJC
            dispatch_retain(failureCallbackQueue);
#endif
            _failureCallbackQueue = failureCallbackQueue;
        }
    }
}

- (void)setCompletionBlockWithSuccess:(void (^)(VKHTTPOperation *operation, id responseObject))success
                              failure:(void (^)(VKHTTPOperation *operation, NSError *error))failure {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
#pragma clang diagnostic ignored "-Wgnu"
    self.completionBlock = ^{
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
                    success(self, self.responseData);
                });
            }
        }
    };
#pragma clang diagnostic pop
}

@end
