//
//  VKApiObjectArray.m
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

#import "VKApiObjectArray.h"
#import "VKUtil.h"

@interface VKApiObjectArray ()
@property(nonatomic, readwrite) NSUInteger count;
@end

@implementation VKApiObjectArray
- (instancetype)initWithDictionary:(NSDictionary *)dict {
    return [self initWithDictionary:dict objectClass:self.objectClass];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict objectClass:(Class)objectClass {
    id response = dict[@"response"];
    if (response && [response isKindOfClass:[NSArray class]]) {
        self = [self initWithArray:response objectClass:objectClass];
    }
    else {
        NSDictionary *targetDict = VK_ENSURE_DICT(response ? response : dict);
        self = [super initWithDictionary:targetDict];
        self.items = [self parseItems:VK_ENSURE_ARRAY(targetDict[@"items"]) asClass:objectClass];
    }

    return self;
}

- (instancetype)initWithArray:(NSArray *)array objectClass:(Class)objectClass {

    self = [super init];
    self.items = [self parseItems:array asClass:objectClass];
    self.count = self.items.count;
    return self;
}

- (instancetype)initWithArray:(NSArray *)array {
    return [self initWithArray:array objectClass:self.objectClass];
}

- (NSMutableArray *)parseItems:(NSArray *)toParse asClass:(Class)objectClass {
    NSMutableArray *listOfParsedObjects = [NSMutableArray new];
    for (id userDictionary in toParse) {
        if ([userDictionary isKindOfClass:objectClass])
            [listOfParsedObjects addObject:userDictionary];
        else if ([userDictionary isKindOfClass:[NSDictionary class]])
            [listOfParsedObjects addObject:[(VKApiObject *) [objectClass alloc] initWithDictionary:userDictionary]];
        else
            [listOfParsedObjects addObject:userDictionary];
    }
    return listOfParsedObjects;

}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained[])buffer count:(NSUInteger)len {
    return [self.items countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndex:(NSInteger)idx {
    return self.items[idx];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.items[idx];
}

- (NSEnumerator *)objectEnumerator {
    return self.items.objectEnumerator;
}

- (NSEnumerator *)reverseObjectEnumerator {
    return self.items.reverseObjectEnumerator;
}

- (void)addObject:(id)object {
    [self.items addObject:object];
    self.count = self.items.count;
}

- (void)removeObject:(id)object {
    [self.items removeObject:object];
    self.count = self.items.count;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    [self.items insertObject:object atIndex:index];
    self.count = self.items.count;
}

- (id)firstObject {
    return [self.items firstObject];
}

- (id)lastObject {
    return [self.items lastObject];
}

- (NSDictionary *)serialize {
    return nil;
}

- (void)serializeTo:(NSMutableDictionary *)dict withName:(NSString *)name {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.items.count];
    for (id object in self.items) {
        if ([object respondsToSelector:@selector(serialize)])
            [result addObject:[object serialize]];
        else
            [result addObject:object];
    }
    dict[name] = result;
}

- (Class)objectClass {
    return [VKApiObject class];
}

+ (instancetype)createWithDictionary:(NSDictionary *)dict {
    return [[self alloc] initWithDictionary:dict];
}

+ (instancetype)createWithArray:(NSArray *)array {
    return [[self alloc] initWithArray:array];
}
@end
