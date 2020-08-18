//
//  VKPhotoSize.h
//  sdk
//
//  Created by Roman Truba on 11.08.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKApiObjectArray.h"

@interface VKPhotoSize : VKApiObject
@property(nonatomic, readwrite, copy) NSString *src;
@property(nonatomic, readwrite, copy) NSNumber *width;
@property(nonatomic, readwrite, copy) NSNumber *height;
@property(nonatomic, readwrite, copy) NSString *type;
@end

@interface VKPhotoSizes : VKApiObjectArray<VKPhotoSize*>
- (VKPhotoSize *)photoSizeWithType:(NSString *)type;
@end
