//
//  VKApiGroups.h
//  sdk
//
//  Created by Roman Truba on 16.07.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKApiBase.h"

@interface VKApiGroups : VKApiBase
/**
https://vk.com/dev/groups.get
@param params use parameters from description with VK_API prefix, e.g. VK_API_GROUP_ID, VK_API_FIELDS
@return Request for load
*/
- (VKRequest *)getById:(NSDictionary *)params;
@end
