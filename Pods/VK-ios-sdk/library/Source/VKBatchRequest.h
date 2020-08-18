//
//  VKBatchRequest.h
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
#import "VKRequest.h"

/**
Used for execution bunch of methods at time, and receive results of that methods in array
*/
@interface VKBatchRequest : VKObject {
@private

    NSMutableArray *_requests;
    NSMutableArray *_responses;
    BOOL _canceled;
}
/// Specify completion block for request
@property(nonatomic, copy) void (^completeBlock)(NSArray *responses);
/// Specity error (HTTP or API) block for request.
@property(nonatomic, copy) void (^errorBlock)(NSError *error);

/**
Initializes batch processing with requests
@param firstRequest ,... A comma-separated list of requests should be loaded, ending with nil.
@return Prepared request
*/
- (instancetype)initWithRequests:(VKRequest *)firstRequest, ...NS_REQUIRES_NIL_TERMINATION;

/**
Initializes batch processing with requests array
@param requests Array of requests should be loaded.
@return Prepared request
*/
- (instancetype)initWithRequestsArray:(NSArray *)requests;

/**
Executes batch request
@param completeBlock will receive result of passed requests
@param errorBlock called if any request did fail
*/
- (void)executeWithResultBlock:(void (^)(NSArray *responses))completeBlock errorBlock:(void (^)(NSError *error))errorBlock;

/**
Cancel current batch operation
*/
- (void)cancel;
@end
