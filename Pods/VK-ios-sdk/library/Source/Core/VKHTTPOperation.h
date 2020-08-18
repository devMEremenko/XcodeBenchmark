//
//  VKHTTPOperation.h
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

#import <Foundation/Foundation.h>
#import "VKOperation.h"

extern NSString *const VKNetworkingOperationDidStart;

@class VKRequest;

/**
VK URL operation subclassing NSOperation.
Based on AFNetworking library ( https://github.com/AFNetworking/AFNetworking )
*/
@interface VKHTTPOperation : VKOperation <NSURLConnectionDataDelegate, NSURLConnectionDelegate, NSCoding, NSCopying>
@property(nonatomic, strong) VKRequest *loadingRequest;

/**
Creates new operation with prepared request.
@param request Prepared VK request to API
@return Initialized operation
*/
+ (instancetype)operationWithRequest:(VKRequest *)request;

///-------------------------------
/// @name Accessing Run Loop Modes
///-------------------------------

/**
The run loop modes in which the operation will run on the network thread. By default, this is a single-member set containing `NSRunLoopCommonModes`.
*/
@property(nonatomic, strong) NSSet *runLoopModes;

///-----------------------------------------
/// @name Getting URL Connection Information
///-----------------------------------------

/**
The vk request initialized that operation
*/
@property(readonly, nonatomic, weak) VKRequest *vkRequest;
/**
The request used by the operation's connection.
*/
@property(readonly, nonatomic, strong) NSURLRequest *request;

/**
The error, if any, that occurred in the lifecycle of the request.
*/
@property(readonly, nonatomic, strong) NSError *error;

///----------------------------
/// @name Getting Response Data
///----------------------------

/**
The data received during the request.
*/
@property(readonly, nonatomic, strong) NSData *responseData;

/**
The string representation of the response data.
*/
@property(readonly, nonatomic, copy) NSString *responseString;

/**
The json representation of the response data.
*/
@property(readonly, nonatomic, copy) id responseJson;

/**
The last HTTP response received by the operation's connection.
*/
@property(readonly, nonatomic, strong) NSHTTPURLResponse *response;

/**
The callback dispatch queue on success. If `NULL` (default), the main queue is used.
*/
@property(nonatomic, assign) dispatch_queue_t successCallbackQueue;

/**
The callback dispatch queue on failure. If `NULL` (default), the main queue is used.
*/
@property(nonatomic, assign) dispatch_queue_t failureCallbackQueue;

/**
Init this operation with URL request
@param urlRequest request to load
@return initialized operation
*/
- (instancetype)initWithURLRequest:(NSURLRequest *)urlRequest;

/**
Pauses the execution of the request operation.

A paused operation returns `NO` for `-isReady`, `-isExecuting`, and `-isFinished`. As such, it will remain in an `NSOperationQueue` until it is either cancelled or resumed. Pausing a finished, cancelled, or paused operation has no effect.
*/
- (void)pause;

/**
Whether the request operation is currently paused.

@return `YES` if the operation is currently paused, otherwise `NO`.
*/
- (BOOL)isPaused;

/**
Resumes the execution of the paused request operation.

Pause/Resume behavior varies depending on the underlying implementation for the operation class. In its base implementation, resuming a paused requests restarts the original request. However, since HTTP defines a specification for how to request a specific content range, `AFHTTPRequestOperation` will resume downloading the request from where it left off, instead of restarting the original request.
*/
- (void)resume;

///----------------------------------------------
/// @name Configuring Backgrounding Task Behavior
///----------------------------------------------

/**
Specifies that the operation should continue execution after the app has entered the background, and the expiration handler for that background task.

@param handler A handler to be called shortly before the application’s remaining background time reaches 0. The handler is wrapped in a block that cancels the operation, and cleans up and marks the end of execution, unlike the `handler` parameter in `UIApplication -beginBackgroundTaskWithExpirationHandler:`, which expects this to be done in the handler itself. The handler is called synchronously on the main thread, thus blocking the application’s suspension momentarily while the application is notified.
*/
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;

/**
Sets a callback to be called when an undetermined number of bytes have been uploaded to the server.

@param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes three arguments: the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times, and will execute on the main thread.
*/
- (void)setUploadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

/**
Sets a callback to be called when an undetermined number of bytes have been downloaded from the server.

@param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times, and will execute on the main thread.
*/
- (void)setDownloadProgressBlock:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))block;

/**
Sets the `completionBlock` property with a block that executes either the specified success or failure block, depending on the state of the request on completion. If `error` returns a value, which can be caused by an unacceptable status code or content type, then `failure` is executed. Otherwise, `success` is executed.

This method should be overridden in subclasses in order to specify the response object passed into the success block.

@param success The block to be executed on the completion of a successful request. This block has no return value and takes two arguments: the receiver operation and the object constructed from the response data of the request.
@param failure The block to be executed on the completion of an unsuccessful request. This block has no return value and takes two arguments: the receiver operation and the error that occurred during the request.
*/
- (void)setCompletionBlockWithSuccess:(void (^)(VKHTTPOperation *operation, id responseObject))success
                              failure:(void (^)(VKHTTPOperation *operation, NSError *error))failure;
@end

