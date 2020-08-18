//
//  VKPhotoSize.m
//  sdk
//
//  Created by Roman Truba on 11.08.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKPhotoSize.h"

@implementation VKPhotoSize
@end

@implementation VKPhotoSizes {
    NSDictionary *sizesDictionary;
}
- (Class)objectClass {
    return [VKPhotoSize class];
}

- (instancetype)initWithArray:(NSArray *)array {
    self = [super initWithArray:array];
    NSMutableDictionary *sizes = [NSMutableDictionary new];
    for (VKPhotoSize *size in self.items) {
        if (!size.type) continue;
        sizes[size.type] = size;
    }
    sizesDictionary = sizes;
    return self;
}

- (VKPhotoSize *)photoSizeWithType:(NSString *)type {
    return sizesDictionary[type];
}
@end
