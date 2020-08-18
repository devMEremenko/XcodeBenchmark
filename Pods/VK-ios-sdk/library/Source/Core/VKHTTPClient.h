//
//  VKHttpClient.h
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

#import "VKObject.h"

@class VKHTTPOperation;

/**
Class for NSURLRequests generation, made for VK API.
Based on AFNetworking library ( https://github.com/AFNetworking/AFNetworking )
*/
@interface VKHTTPClient : VKObject <NSCoding>

///-------------------------------
/// @name Initialization
///-------------------------------

/**
Creates and initializes an `VKHTTPClient` object with the specified base URL.

@return The newly-initialized HTTP client
*/
+ (instancetype)getClient;

/**
The operation queue which manages operations enqueued by the HTTP client.
*/
@property(readonly, nonatomic, strong) NSOperationQueue *operationQueue;

///-------------------------------
/// @name Operations with default headers
///-------------------------------

/**
Returns the value for the HTTP headers set in request objects created by the HTTP client.

@param header The HTTP header to return the default value for

@return The default value for the HTTP header, or `nil` if unspecified
*/
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.

@param header The HTTP header to set a default value for
@param value The value set as default for the specified header, or `nil
*/
- (void)setDefaultHeader:(NSString *)header
                   value:(NSString *)value;

///-------------------------------
/// @name Preparing requests
///-------------------------------

/**
Creates an `NSMutableURLRequest` object with the specified HTTP method and path.

If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.

@param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
@param path The path to be appended to the HTTP client's base URL and used as the request URL. If `nil`, no path will be appended to the base URL.
@param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
@param secure Use HTTPS or not

@return An `NSMutableURLRequest` object
*/
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                    secure:(BOOL)secure;

/**
Creates an `NSMutableURLRequest` object with the specified HTTP method and path, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2

Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.

@param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
@param path The path to be appended to the HTTP client's base URL and used as the request URL.
@param images Upload images objects to append

@return An `NSMutableURLRequest` object
*/
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                                 images:(NSArray *)images;

///-------------------------------
/// @name Enqueuing operations
///-------------------------------

/**
Enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue.

@param operation The HTTP request operation to be enqueued.
*/
- (void)enqueueOperation:(NSOperation *)operation;

/**
Enqueues the specified request operations into a batch. When each request operation finishes, the specified progress block is executed, until all of the request operations have finished, at which point the completion block also executes.

@param operations The request operations used to be batched and enqueued.
@param progressBlock A block object to be executed upon the completion of each request operation in the batch. This block has no return value and takes two arguments: the number of operations that have already finished execution, and the total number of operations.
@param completionBlock A block object to be executed upon the completion of all of the request operations in the batch. This block has no return value and takes a single argument: the batched request operations.
*/
- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock;

@end
