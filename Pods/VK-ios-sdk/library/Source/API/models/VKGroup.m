//
//  VKGroup.m
//  sdk
//
//  Created by Roman Truba on 16.07.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKGroup.h"

@implementation VKGeoPlace
@end

@implementation VKGroupContact
@end

@implementation VKGroupContacts

-(Class)objectClass {
    return [VKGroupContact class];
}

@end

@implementation VKGroupLink
@end

@implementation VKGroupLinks

-(Class)objectClass {
    return [VKGroupLink class];
}

@end

@implementation VKGroup

@synthesize description = _description;

@end

@implementation VKGroups

-(Class)objectClass {
    return [VKGroup class];
}

@end
