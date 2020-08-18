//
//  VKAudio.m
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

#import "VKAudio.h"
#import "VKUser.h"

@implementation VKAudio
@end

@implementation VKAudios
- (Class)objectClass {
    return [VKAudio class];
}

//Parse first user in array (in some cases)
- (NSMutableArray *)parseItems:(NSArray *)toParse asClass:(Class)objectClass {
    NSMutableArray *listOfParsedObjects = [NSMutableArray new];
    for (id objectDict in toParse) {
        if ([objectDict isKindOfClass:objectClass])
            [listOfParsedObjects addObject:objectDict];
        else if ([objectDict isKindOfClass:[NSDictionary class]]) {
            if ([toParse firstObject] == objectDict && objectDict[@"name"]) {
                self.user = [[VKUser alloc] initWithDictionary:objectDict];
            } else {
                [listOfParsedObjects addObject:[(VKApiObject *) [objectClass alloc] initWithDictionary:objectDict]];
            }
        }
        else
            [listOfParsedObjects addObject:objectDict];
    }
    return listOfParsedObjects;
}
@end
