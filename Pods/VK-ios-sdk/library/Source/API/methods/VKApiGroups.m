//
//  VKApiGroups.m
//  sdk
//
//  Created by Roman Truba on 16.07.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKApiGroups.h"
#import "VKGroup.h"

@implementation VKApiGroups
- (VKRequest *)getById:(NSDictionary *)params {
    return [self prepareRequestWithMethodName:@"getById"
                                   parameters:params
                                   modelClass:[VKGroups class]];
}
@end
