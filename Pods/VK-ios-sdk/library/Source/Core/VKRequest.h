//
//  VKRequest.h
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
#import "VKResponse.h"
#import "VKApiConst.h"
#import "VKObject.h"


/**
Creates and debug timings for VKRequest
*/
@interface VKRequestTiming : VKObject
/// Date of request start
@property(nonatomic, strong) NSDate *startTime;
/// Date of request finished (after all operations)
@property(nonatomic, strong) NSDate *finishTime;
/// Interval of networking load time
@property(nonatomic, assign) NSTimeInterval loadTime;
/// Interval of model parsing time
@property(nonatomic, assign) NSTimeInterval parseTime;
/// Total time, as difference (finishTime - startTime)
@property(nonatomic, readonly) NSTimeInterval totalTime;
@end

/**
 Class for execution API-requests.
 
 See example requests below:
 
 1) A plain request
    
    VKRequest *usersReq = [[VKApi users] get];
 
 2) A request with parameters
 
    VKRequest *usersReq = [[VKApi users] get:@{VK_API_FIELDS : @"photo_100"}];
 
 3) A request with predetermined maximum number of attempts. For example, take 10 attempts until succeed or an API error occurs:
 
    VKRequest *postReq = [[VKApi wall] post:@{VK_API_MESSAGE : @"Test"}];
    postReq.attempts = 10;
    //or infinite
    //postReq.attempts = 0;
 
 4) You can build a request for any public method of VK API
 
    VKRequest *getWall = [VKRequest requestWithMethod:@"wall.get" andParameters:@{VK_API_OWNER_ID : @"-1"}];
 
 5) Also there are some special requests for uploading a photos to a user's wall, user albums and other
 
    VKRequest *request = [VKApi uploadWallPhotoRequest:[UIImage imageNamed:@"my_photo"] parameters:[VKImageParameters pngImage] userId:0 groupId:0 ];
 
 
 After you have prepared a request, you execute it and you may receive some data or error
 
    [usersReq executeWithResultBlock:^(VKResponse *response) {
        NSLog(@"Json result: %@", response.json);
    } errorBlock:^(NSError * error) {
        if (error.code != VK_API_ERROR) {
            [error.vkError.request repeat];
        } else {
            NSLog(@"VK error: %@", error);
        }
    }];
 
*/
@interface VKRequest : VKObject
/// Specify progress for uploading or downloading. Useless for text requests (because gzip encoding bytesTotal will always return -1)

@property(nonatomic, copy) void (^progressBlock)(VKProgressType progressType, long long bytesLoaded, long long bytesTotal);
/// Specify completion block for request
@property(nonatomic, copy) void (^completeBlock)(VKResponse *response);
/// Specity error (HTTP or API) block for request.
@property(nonatomic, copy) void (^errorBlock)(NSError *error);
/// Specify attempts for request loading if caused HTTP-error. 0 for infinite
@property(nonatomic, assign) int attempts;
/// Use HTTPS requests (by default is YES). If http-request is impossible (user denied no https access), SDK will load https version
@property(nonatomic, assign) BOOL secure;
/// Sets current system language as default for API data
@property(nonatomic, assign) BOOL useSystemLanguage;
/// Set to NO if you don't need automatic model parsing
@property(nonatomic, assign) BOOL parseModel;
/// Set to YES if you need info about request timing
@property(nonatomic, assign) BOOL debugTiming;
/// Timeout for this request
@property(nonatomic, assign) NSInteger requestTimeout;
/// Sets dispatch queue for returning result
@property(nonatomic, assign) dispatch_queue_t responseQueue;
/// Set to YES if you need to freeze current thread for response
@property(nonatomic, assign) BOOL waitUntilDone;
/// Returns method for current request, e.g. users.get
@property(nonatomic, readonly) NSString *methodName;
/// Returns HTTP-method for current request
@property(nonatomic, readonly) NSString *httpMethod;
/// Returns list of method parameters (without common parameters)
@property(nonatomic, readonly) NSDictionary *methodParameters;
/// Returns http operation that can be enqueued
@property(nonatomic, readonly) NSOperation *executionOperation;
/// Returns info about request timings
@property(nonatomic, readonly) VKRequestTiming *requestTiming;
/// Return YES if current request was started
@property(nonatomic, readonly) BOOL isExecuting;
/// Return YES if current request was started
@property(nonatomic, copy) NSArray *preventThisErrorsHandling;

///-------------------------------
/// @name Preparing requests
///-------------------------------


/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @param httpMethod HTTP method for execution, e.g. GET, POST
 @return Complete request object for execute or configure method
 @deprecated Use requestWithMethod:parameters: instead
*/
+ (instancetype)requestWithMethod:(NSString *)method
                    andParameters:(NSDictionary *)parameters
                    andHttpMethod:(NSString *)httpMethod __deprecated;

/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @return Complete request object for execute or configure method
 @deprecated Use requestWithMethod:parameters: instead
*/
+ (instancetype)requestWithMethod:(NSString *)method
                    andParameters:(NSDictionary *)parameters __deprecated;

/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @param modelClass class for automatic parse
 @return Complete request object for execute or configure method
 */
+ (instancetype)requestWithMethod:(NSString *)method
                    andParameters:(NSDictionary *)parameters
                       modelClass:(Class)modelClass __deprecated;

/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @param httpMethod HTTP method for execution, e.g. GET, POST
 @param modelClass class for automatic parse
 @return Complete request object for execute or configure method
 @deprecated Use requestWithMethod:andParameters:modelClass: instead
 */
+ (instancetype)requestWithMethod:(NSString *)method
                    andParameters:(NSDictionary *)parameters
                    andHttpMethod:(NSString *)httpMethod
                     classOfModel:(Class)modelClass __deprecated;

/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @return Complete request object for execute or configure method
 */
+ (instancetype)requestWithMethod:(NSString *)method
                       parameters:(NSDictionary *)parameters;

/**
 Creates new request with parameters. See documentation for methods here https://vk.com/dev/methods
 @param method API-method name, e.g. audio.get
 @param parameters method parameters
 @param modelClass class for automatic parse
 @return Complete request object for execute or configure method
 */
+ (instancetype)requestWithMethod:(NSString *)method
                       parameters:(NSDictionary *)parameters
                       modelClass:(Class)modelClass;

/**
Creates new request for upload image to url
@param url url for upload, which was received from special methods
@param photoObjects VKPhoto object describes photos
@return Complete request object for execute
*/
+ (instancetype)photoRequestWithPostUrl:(NSString *)url
                             withPhotos:(NSArray *)photoObjects;

/**
Prepares NSURLRequest and returns prepared url request for current vkrequest
@return Prepared request used for loading
*/
- (NSURLRequest *)getPreparedRequest;

///-------------------------------
/// @name Execution
///-------------------------------
/**
Executes that request, and returns result to blocks
@param completeBlock called if there were no HTTP or API errors, returns execution result.
@param errorBlock called immediately if there was API error, or after <b>attempts</b> tries if there was an HTTP error
*/
- (void)executeWithResultBlock:(void (^)(VKResponse *response))completeBlock
                    errorBlock:(void (^)(NSError *error))errorBlock;

/**
Register current request for execute after passed request, if passed request is successful. If it's not, errorBlock will be called.
@param request after which request must be called that request
@param completeBlock called if there were no HTTP or API errors, returns execution result.
@param errorBlock called immediately if there was API error, or after <b>attempts</b> tries if there was an HTTP error
*/
- (void)executeAfter:(VKRequest *)request
     withResultBlock:(void (^)(VKResponse *response))completeBlock
          errorBlock:(void (^)(NSError *error))errorBlock;

/**
Starts loading of prepared request. You can use it instead of executeWithResultBlock
*/
- (void)start;

/**
 Creates loading operation for this request
 */
- (NSOperation *)createExecutionOperation;

/**
Repeats this request with initial parameters and blocks.
Used attempts will be set to 0.
*/
- (void)repeat;

/**
Cancel current request. Result will be not passed. errorBlock will be called with error code
*/
- (void)cancel;

///-------------------------------
/// @name Operating with parameters
///-------------------------------
/**
 Adds additional parameters to that request
 
 @param extraParameters parameters supposed to be added
*/
- (void)addExtraParameters:(NSDictionary *)extraParameters;

/** 
 Specify language for API request
 */
- (void)setPreferredLang:(NSString *)lang;

@end
