//
//  VKRequest.m
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

#import <NSString+MD5.h>

#import "VKSdk.h"
#import "OrderedDictionary.h"
#import "VKAuthorizeController.h"
#import "VKHTTPClient.h"
#import "VKJSONOperation.h"
#import "VKRequestsScheduler.h"

#define SUPPORTED_LANGS_ARRAY @[@"ru", @"en", @"uk", @"es", @"fi", @"de", @"it"]

void vksdk_dispatch_on_main_queue_now(void(^block)(void)) {
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface VKRequestTiming () {
    NSDate *_parseStartTime;
}
@end

@interface VKError (CaptchaRequest)
- (void)notifyCaptchaRequired;

- (void)notifyAuthorizationFailed;
@end

@implementation VKRequestTiming

- (NSString *)description {
    return [NSString stringWithFormat:@"<VKRequestTiming: %p (load: %f, parse: %f, total: %f)>",
                                      self, _loadTime, _parseTime, self.totalTime];
}

- (void)started {
    _startTime = [NSDate new];
}

- (void)loaded {
    _loadTime = [[NSDate new] timeIntervalSinceDate:_startTime];
}

- (void)parseStarted {
    _parseStartTime = [NSDate new];
}

- (void)parseFinished {
    _parseTime = [[NSDate new] timeIntervalSinceDate:_parseStartTime];
}

- (void)finished {
    _finishTime = [NSDate new];
}

- (NSTimeInterval)totalTime {
    return [_finishTime timeIntervalSinceDate:_startTime];
}
@end

@interface VKAccessToken (HttpsRequired)
- (void)setAccessTokenRequiredHTTPS;
@end

@interface VKRequest () {
    /// Semaphore for blocking current thread
    dispatch_semaphore_t _waitUntilDoneSemaphore;
    CGFloat _waitMultiplier;
}
@property(nonatomic, readwrite, strong) VKRequestTiming *requestTiming;
/// Selected method name
@property(nonatomic, strong) NSString *methodName;
/// HTTP method for loading
@property(nonatomic, strong) NSString *httpMethod;
/// Passed parameters for method
@property(nonatomic, strong) NSDictionary *methodParameters;
/// Method parametes with common parameters
@property(nonatomic, strong) OrderedDictionary *preparedParameters;
/// Url for uploading files
@property(nonatomic, strong) NSString *uploadUrl;
/// Requests that should be called after current request.
@property(nonatomic, strong) NSMutableArray *postRequestsQueue;
/// Class for model parsing
@property(nonatomic, strong) Class modelClass;
/// Paths to photos
@property(nonatomic, strong) NSArray *photoObjects;
/// How much times request was loaded
@property(readwrite, assign) int attemptsUsed;
/// This request response
@property(nonatomic, strong) VKResponse *response;
/// This request error
@property(nonatomic, strong) NSError *error;
/// Language specified by user
@property(nonatomic, copy) NSString *requestLang;
/// Returns http operation that can be enqueued
@property(nonatomic, readwrite, strong) NSOperation *executionOperation;

@property(nonatomic, readwrite, strong) VKAccessToken *specialToken;

@end

@implementation VKRequest


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.responseQueue = nil;
}

+ (dispatch_queue_t)processingQueue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

#pragma mark Deprecated

+ (instancetype)requestWithMethod:(NSString *)method andParameters:(NSDictionary *)parameters andHttpMethod:(NSString *)httpMethod {
    return [self requestWithMethod:method andParameters:parameters];
}

+ (instancetype)requestWithMethod:(NSString *)method
                    andParameters:(NSDictionary *)parameters {
    return [self requestWithMethod:method andParameters:parameters modelClass:nil];
}

+ (instancetype)requestWithMethod:(NSString *)method andParameters:(NSDictionary *)parameters andHttpMethod:(NSString *)httpMethod classOfModel:(Class)modelClass {
    return [self requestWithMethod:method andParameters:parameters modelClass:modelClass];
}

+ (instancetype)requestWithMethod:(NSString *)method andParameters:(NSDictionary *)parameters modelClass:(Class)modelClass {
    return [self requestWithMethod:method parameters:parameters modelClass:modelClass];
}

#pragma mark Init

+ (instancetype)requestWithMethod:(NSString *)method
                       parameters:(NSDictionary *)parameters {
    return [self requestWithMethod:method parameters:parameters modelClass:nil];
}

+ (instancetype)requestWithMethod:(NSString *)method parameters:(NSDictionary *)parameters modelClass:(Class)modelClass {
    VKRequest *newRequest = [self new];
    //Common parameters
    newRequest.parseModel = modelClass != nil;
    newRequest.requestTimeout = 25;
    
    newRequest.methodName = method;
    newRequest.methodParameters = parameters;
    newRequest.httpMethod = @"POST";
    newRequest.modelClass = modelClass;
    return newRequest;
}

+ (instancetype)photoRequestWithPostUrl:(NSString *)url withPhotos:(NSArray *)photoObjects; {
    VKRequest *newRequest = [self new];
    newRequest.attempts = 10;
    newRequest.httpMethod = @"POST";
    newRequest.uploadUrl = url;
    newRequest.photoObjects = photoObjects;
    return newRequest;
}

- (id)init {
    if (self = [super init]) {
        self.attemptsUsed = 0;
        //If system language is not supported, we use english
        self.requestLang = @"en";
        //By default there is 1 attempt for loading.
        self.attempts = 1;
        //By default we use system language.
        self.useSystemLanguage = YES;
        self.secure = YES;

        _waitMultiplier = 1.f;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<VKRequest: %p; Method: %@ (%@)>", self, self.methodName, self.httpMethod];
}

#pragma mark Execution

- (void)executeWithResultBlock:(void (^)(VKResponse *))completeBlock
                    errorBlock:(void (^)(NSError *))errorBlock {
    self.completeBlock = completeBlock;
    self.errorBlock = errorBlock;

    if (!self.waitUntilDone) {
        [[VKRequestsScheduler instance] scheduleRequest:self];
    } else {
        [self start];
    }
}

- (void)executeAfter:(VKRequest *)request
     withResultBlock:(void (^)(VKResponse *response))completeBlock
          errorBlock:(void (^)(NSError *error))errorBlock {
    self.completeBlock = completeBlock;
    self.errorBlock = errorBlock;
    [request addPostRequest:self];
}

- (void)addPostRequest:(VKRequest *)postRequest {
    if (!_postRequestsQueue)
        _postRequestsQueue = [NSMutableArray new];
    [_postRequestsQueue addObject:postRequest];
}

- (NSURLRequest *)getPreparedRequest {
    //Add common parameters to parameters list
    if (!_preparedParameters && !_uploadUrl) {
        _preparedParameters = [[OrderedDictionary alloc] initWithCapacity:self.methodParameters.count * 2];
        for (NSString *key in self.methodParameters) {
            id value = self.methodParameters[key];
            if ([value isKindOfClass:NSArray.class]) {
                value = [value componentsJoinedByString:@","];
            }
            [_preparedParameters setObject:value forKey:key];
        }
        VKAccessToken *token = [VKSdk accessToken] ?: self.specialToken;
        if (token != nil) {
            if (token.accessToken != nil) {
                [_preparedParameters setObject:token.accessToken forKey:VK_API_ACCESS_TOKEN];
            }
            if (!(self.secure || token.secret) || token.httpsRequired)
                self.secure = YES;
        }
        if (self.specialToken) {
            self.secure = YES;
        }

        //Set actual version of API
        [_preparedParameters setObject:[VKSdk instance].apiVersion forKey:@"v"];
        //Set preferred language for request
        [_preparedParameters setObject:[self language] forKey:VK_API_LANG];
        //Set current access token from SDK object

        if (self.secure) {
            //If request is secure, we need all urls as https
            [_preparedParameters setObject:@"1" forKey:@"https"];
        }
        if (token && token.secret) {
            //If it not, generate signature of request
            NSString *sig = [self generateSig:_preparedParameters token:token];
            [_preparedParameters setObject:sig forKey:VK_API_SIG];
        }
        //From that moment you cannot modify parameters.
        //Specially for http loading
    }

    NSMutableURLRequest *request = nil;
    if (!_uploadUrl) {
        request = [[VKHTTPClient getClient] requestWithMethod:self.httpMethod path:self.methodName parameters:_preparedParameters secure:self.secure];
    }
    else {
        request = [[VKHTTPClient getClient] multipartFormRequestWithMethod:@"POST" path:_uploadUrl images:_photoObjects];
    }
    [request setTimeoutInterval:self.requestTimeout];
    [request setValue:_preparedParameters[VK_API_LANG] forHTTPHeaderField:@"Accept-Language"];
    return request;
}

- (NSOperation *)createExecutionOperation {
    VKJSONOperation *operation = [VKJSONOperation operationWithRequest:self];
    if (!operation)
        return nil;
    if (_debugTiming) {
        _requestTiming = [VKRequestTiming new];
    }

    [operation setCompletionBlockWithSuccess:^(VKHTTPOperation *completedOperation, id JSON) {
        [self->_requestTiming loaded];
        if (self->_executionOperation.isCancelled) {
            return;
        }
        if ([JSON objectForKey:@"error"]) {
            VKError *error = [VKError errorWithJson:[JSON objectForKey:@"error"]];
            if ([self processCommonError:error]) {
                return;
            }
            [self provideError:[NSError errorWithVkError:error]];
            return;
        }
        [self provideResponse:JSON responseString:completedOperation.responseString];
    } failure:^(VKHTTPOperation *completedOperation, NSError *error) {
        [self->_requestTiming loaded];
        if (self->_executionOperation.isCancelled) {
            return;
        }
        if (completedOperation.response.statusCode == 200) {
            [self provideResponse:completedOperation.responseJson responseString:completedOperation.responseString];
            return;
        }
        if (self.attempts == 0 || ++self.attemptsUsed < self.attempts) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (300 * NSEC_PER_MSEC)), self.responseQueue,
                    ^(void) {
                        [self executeWithResultBlock:self->_completeBlock errorBlock:self->_errorBlock];
                    });
            return;
        }

        VKError *vkErr = [VKError errorWithCode:completedOperation.response ? completedOperation.response.statusCode : error.code];
        [self provideError:[error copyWithVkError:vkErr]];
        [self->_requestTiming finished];

    }];
    operation.successCallbackQueue = operation.failureCallbackQueue = [VKRequest processingQueue];
    [self setupProgress:operation];
    return operation;
}

- (void)start {
    self.response = nil;
    self.error = nil;

    self.executionOperation = [self createExecutionOperation];
    if (_executionOperation == nil)
        return;

    if (self.debugTiming) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(operationDidStart:) name:VKNetworkingOperationDidStart object:nil];
    }
    if (!self.waitUntilDone) {
        [[VKHTTPClient getClient] enqueueOperation:_executionOperation];
    } else {
        VKHTTPOperation *op = (VKHTTPOperation *) _executionOperation;
        op.successCallbackQueue = op.failureCallbackQueue = [VKRequest processingQueue];
        [[VKHTTPClient getClient] enqueueOperation:_executionOperation];
        if (!_waitUntilDoneSemaphore) {
            _waitUntilDoneSemaphore = dispatch_semaphore_create(0);
            dispatch_semaphore_wait(_waitUntilDoneSemaphore, DISPATCH_TIME_FOREVER);
            if (self.error || self.response) {
                [self finishRequest];
            }
        }
    }
}

- (void)operationDidStart:(NSNotification *)notification {
    if (notification.object == _executionOperation) {
        [self.requestTiming started];
    }
}

- (void)provideResponse:(id)JSON responseString:(NSString *)response {
    VKResponse *vkResp = [VKResponse new];
    vkResp.responseString = response;
    vkResp.request = self;
    if (JSON[@"response"]) {
        vkResp.json = JSON[@"response"];

        if (self.parseModel && _modelClass) {
            [_requestTiming parseStarted];
            id object = [_modelClass alloc];
            if ([object respondsToSelector:@selector(initWithDictionary:)]) {
                vkResp.parsedModel = [object initWithDictionary:JSON];
            }
            [_requestTiming parseFinished];
        }
    }
    else {
        vkResp.json = JSON;
    }

    for (VKRequest *postRequest in _postRequestsQueue) {
        [[VKRequestsScheduler instance] scheduleRequest:postRequest];
    }
    [_requestTiming finished];
    self.response = vkResp;
    if (_executionOperation.isCancelled) {
        return;
    }
    if (self.waitUntilDone) {
        dispatch_semaphore_signal(_waitUntilDoneSemaphore);
    } else {
        [self finishRequest];
    }
}

- (void)provideError:(NSError *)error {
    error.vkError.request = self;
    self.error = error;
    if (self.waitUntilDone) {
        dispatch_semaphore_signal(_waitUntilDoneSemaphore);
    }
    else {
        [self finishRequest];
    }
}

- (void)finishRequest {
    void (^block)(void) = NULL;
    if (self.error) {
        NSError *error = self.error;
        block = ^{
            if (self.errorBlock) {
                self.errorBlock(error);
            }
            for (VKRequest *postRequest in self->_postRequestsQueue) {
                if (postRequest.errorBlock) {
                    postRequest.errorBlock(error);
                }
            }
        };
        self.error = nil;
    } else {
        block = ^{
            if (self.completeBlock) {
                self.completeBlock(self.response);
            }
        };
    }
    if (self.waitUntilDone) {
        block();
    } else {
        dispatch_async(self.responseQueue, block);
    }
}

- (void)repeat {
    _attemptsUsed = 0;
    _preparedParameters = nil;
    [self executeWithResultBlock:_completeBlock errorBlock:_errorBlock];
}

- (void)cancel {
    self.executionOperation.completionBlock = nil;
    [self.executionOperation cancel];
    self.executionOperation = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.error = [NSError errorWithVkError:[VKError errorWithCode:VK_API_CANCELED]];
    [self finishRequest];

}

- (void)setupProgress:(VKHTTPOperation *)operation {
    if (self.progressBlock) {
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            if (self.progressBlock) {
                self.progressBlock(VKProgressTypeUpload, totalBytesWritten, totalBytesExpectedToWrite);
            }
        }];
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            if (self.progressBlock) {
                self.progressBlock(VKProgressTypeDownload, totalBytesRead, totalBytesExpectedToRead);
            }
        }];
    }
}

- (void)addExtraParameters:(NSDictionary *)extraParameters {
    if (!_methodParameters)
        _methodParameters = [extraParameters mutableCopy];
    else {
        NSMutableDictionary *params = [_methodParameters mutableCopy];
        [params addEntriesFromDictionary:extraParameters];
        _methodParameters = params;
    }
}

#pragma mark Sevice

- (NSString *)generateSig:(OrderedDictionary *)params token:(VKAccessToken *)token {
    //Read description here https://vk.com/dev/api_nohttps
    //First of all, we need key-value pairs in order of request
    NSMutableArray *paramsArray = [NSMutableArray arrayWithCapacity:params.count];
    for (NSString *key in params) {
        [paramsArray addObject:[key stringByAppendingFormat:@"=%@", params[key]]];
    }
    //Then we generate "request string" /method/{METHOD_NAME}?{GET_PARAMS}{POST_PARAMS}
    NSString *requestString = [NSString stringWithFormat:@"/method/%@?%@", _methodName, [paramsArray componentsJoinedByString:@"&"]];
    requestString = [requestString stringByAppendingString:token.secret];
    return [requestString vks_md5];
}

- (BOOL)processCommonError:(VKError *)error {
    if (error.errorCode == VK_API_ERROR) {
        error.apiError.request = self;
        if ([self.preventThisErrorsHandling containsObject:@(error.apiError.errorCode)]) {
            return NO;
        }
        if (error.apiError.errorCode == 5) {
            vksdk_dispatch_on_main_queue_now(^{
                [error.apiError notifyAuthorizationFailed];
            });
            return NO;
        }
        if (error.apiError.errorCode == 6) {
            //Too many requests per second
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (_waitMultiplier * NSEC_PER_SEC)), [[self class] processingQueue], ^{
                self->_waitMultiplier *= ((arc4random() % 10) + 10) / 10.f;
                [self repeat];
            });
            return YES;
        }
        if (error.apiError.errorCode == 14) {
            //Captcha
            vksdk_dispatch_on_main_queue_now(^{
                [error.apiError notifyCaptchaRequired];
            });
            return YES;
        }
        else if (error.apiError.errorCode == 16) {
            //Https required
            [[VKSdk accessToken] setAccessTokenRequiredHTTPS];
            [self repeat];
            return YES;
        }
        else if (error.apiError.errorCode == 17) {
            //Validation needed
            vksdk_dispatch_on_main_queue_now(^{
                [VKAuthorizeController presentForValidation:error.apiError];
            });

            return YES;
        }
    }

    return NO;
}

#pragma mark Properties

- (NSString *)language {
    NSString *lang = self.requestLang;
    if (self.useSystemLanguage) {
        static NSString *sysLang = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sysLang = [[[[[NSLocale preferredLanguages] firstObject] componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] firstObject] lowercaseString];
        });
        if ([SUPPORTED_LANGS_ARRAY containsObject:sysLang]) {
            lang = sysLang;
        }
    }
    return lang;
}

- (dispatch_queue_t)responseQueue {
    if (!_responseQueue) {
        return dispatch_get_main_queue();
    }
    return _responseQueue;
}

- (void)setPreferredLang:(NSString *)preferredLang {
    self.requestLang = preferredLang;
    self.useSystemLanguage = NO;
}

- (BOOL)isExecuting {
    return _executionOperation.isExecuting;
}


@end
