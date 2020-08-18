//
//  VKApiObjectArray.h
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
//  copies or suabstantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "VKApiObject.h"

/**
Base class for VK API arrays
*/
@interface VKApiObjectArray<__covariant ApiObjectType : VKApiObject*> : VKApiObject <NSFastEnumeration>
/// Count of items in array
@property(nonatomic, readonly) NSUInteger count;
/// Parsed array items
@property(nonatomic, strong) NSMutableArray<ApiObjectType> *items;

/**
 Initialize object with API json dictionary. This method tries to set all known properties of current class from dictionary
 @param dict API json dictionary
 @param objectClass class of items inside of array
 @return Initialized object
 */
- (instancetype)initWithDictionary:(NSDictionary *)dict objectClass:(Class)objectClass;

/**
 Initialize object with API json array. This method tries to set all known properties of current class from array
 @param array API json array
 @param objectClass class of items inside of array
 @return Initialized object
 */
- (instancetype)initWithArray:(NSArray *)array objectClass:(Class)objectClass;

/**
 Initialize object with any array. items property is sets as passed array, count is a count of items in passed array
 @param array API json array
 @return Initialized object
 */
- (instancetype)initWithArray:(NSArray *)array;

/// Array funtions

- (ApiObjectType)objectAtIndex:(NSInteger)idx;

- (ApiObjectType)objectAtIndexedSubscript:(NSUInteger)idx NS_AVAILABLE(10_8, 6_0);

- (NSEnumerator *)objectEnumerator;

- (NSEnumerator *)reverseObjectEnumerator;

- (void)addObject:(ApiObjectType)object;

- (void)removeObject:(ApiObjectType)object;

- (void)insertObject:(ApiObjectType)object atIndex:(NSUInteger)index;

- (ApiObjectType)firstObject;

- (ApiObjectType)lastObject;

- (void)serializeTo:(NSMutableDictionary *)dict withName:(NSString *)name;

- (Class)objectClass;
@end
