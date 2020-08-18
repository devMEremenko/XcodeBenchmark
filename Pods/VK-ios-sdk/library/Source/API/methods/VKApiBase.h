//
//  VKApiBase.h
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
#import "VKRequest.h"
#import "VKApiConst.h"
#import "VKObject.h"

/**
* Basic class for all API-requests builders (parts)
*/
@interface VKApiBase : VKObject {
@private
    NSString *_methodGroup;  ///< Selected methods group
}
/**
Return group name for current methods builder
@return name of methods group, e.g. users, wall, etc.
*/
- (NSString *)getMethodGroup;

/**
 Builds request and return it for configure and loading
 @param methodName Selected method name
 @param methodParameters Selected method parameters
 @return request to configure and load
 */
- (VKRequest *)prepareRequestWithMethodName:(NSString *)methodName
                                 parameters:(NSDictionary *)methodParameters;

/**
 Builds request and return it for configure and loading
 @param methodName Selected method name
 @param methodParameters Selected method parameters
 @param modelClass Class of model, based on VKApiObject, for model parsing
 @return request to configure and load
 */
- (VKRequest *)prepareRequestWithMethodName:(NSString *)methodName
                                 parameters:(NSDictionary *)methodParameters
                                 modelClass:(Class)modelClass;

@end
