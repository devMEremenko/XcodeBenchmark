//
//  VKGroup.h
//  sdk
//
//  Created by Roman Truba on 16.07.14.
//  Copyright (c) 2014 VK. All rights reserved.
//

#import "VKApiObjectArray.h"
#import "VKUser.h"

/**
 Geo-object type
 */
@interface VKGeoPlace : VKApiObject

@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSNumber *latitude;
@property(nonatomic, strong) NSNumber *longitude;
@property(nonatomic, strong) NSNumber *created;
@property(nonatomic, strong) NSString *icon;
@property(nonatomic, strong) NSNumber *group_id;
@property(nonatomic, strong) NSNumber *group_photo;
@property(nonatomic, strong) NSNumber *checkins;
@property(nonatomic, strong) NSNumber *updated;
@property(nonatomic, strong) NSNumber *type;
@property(nonatomic, strong) NSNumber *country;
@property(nonatomic, strong) NSString *city;
@property(nonatomic, strong) NSString *address;
@property(nonatomic, strong) NSNumber *showmap;
@end

/**
 Object representing contact in group
 */
@interface VKGroupContact : VKApiObject

@property(nonatomic, strong) NSNumber *user_id;
@property(nonatomic, strong) NSString *desc;
@property(nonatomic, strong) NSString *email;

@end

/**
 Array of VKGroupContact objects
 */
@interface VKGroupContacts : VKApiObjectArray<VKGroupContact*>

@end

/**
 Object representing link in group
 */
@interface VKGroupLink : VKApiObject

@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *desc;
@property(nonatomic, strong) NSString *photo_50;
@property(nonatomic, strong) NSString *photo_100;

@end

/**
 Array of VKGroupLink objects
 */
@interface VKGroupLinks : VKApiObjectArray<VKGroupLink *>
@end

@interface VKAddresses : VKApiObject
@property(nonatomic, assign) BOOL is_enabled;
@property(nonatomic, strong) NSNumber *main_address_id;
@end

@interface VKBanInfo : VKApiObject
@property(nonatomic, strong) NSNumber *end_date;
@property(nonatomic, strong) NSString *comment;
@end

@interface VKCoverImage : VKApiObject
@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSNumber *width;
@property(nonatomic, strong) NSNumber *height;
@end

@interface VKCoverImages : VKApiObjectArray<VKCoverImage *>
@end

@interface VKCover: VKApiObject
@property(nonatomic, strong) NSNumber *enabled;
@property(nonatomic, strong) VKCoverImages *images;
@end

@interface VKCurrency : VKApiObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *name;
@end

@interface VKMarket: VKApiObject
@property(nonatomic, strong) NSNumber *enabled;
@property(nonatomic, strong) NSNumber *price_min;
@property(nonatomic, strong) NSNumber *price_max;
@property(nonatomic, strong) NSNumber *main_album_id;
@property(nonatomic, strong) NSNumber *contact_id;
@property(nonatomic, strong) VKCurrency *currency;
@property(nonatomic, strong) NSString *currency_text;
@end

/**
 Group type of VK API. See descriptions here https://vk.com/dev/fields_groups
 */
@interface VKGroup : VKApiObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *screen_name;
@property(nonatomic, strong) NSNumber *is_closed;
@property(nonatomic, strong) NSString *deactivated;
@property(nonatomic, strong) NSNumber *is_admin;
@property(nonatomic, strong) NSNumber *admin_level;
@property(nonatomic, strong) NSNumber *is_member;
@property(nonatomic, strong) NSNumber *is_advertiser;
@property(nonatomic, strong) NSNumber *invited_by;
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSString *photo_50;
@property(nonatomic, strong) NSString *photo_100;
@property(nonatomic, strong) NSString *photo_200;

@property(nonatomic, strong) NSString *activity;
@property(nonatomic, strong) VKAddresses *addresses;
@property(nonatomic, strong) NSNumber *age_limits;
@property(nonatomic, strong) VKBanInfo *ban_info;
@property(nonatomic, strong) NSNumber *can_create_topic;
@property(nonatomic, strong) NSNumber *can_message;
@property(nonatomic, strong) NSNumber *can_post;
@property(nonatomic, strong) NSNumber *can_see_all_posts;
@property(nonatomic, strong) NSNumber *can_upload_doc;
@property(nonatomic, strong) NSNumber *can_upload_video;
@property(nonatomic, strong) VKCity *city;
@property(nonatomic, strong) VKGroupContacts *contacts;
@property(nonatomic, strong) VKCounters *counters;
@property(nonatomic, strong) VKCountry *country;
@property(nonatomic, strong) VKCover *cover;
@property(nonatomic, strong) VKCropPhoto *crop_photo;
@property(nonatomic, strong) NSString *description;
@property(nonatomic, strong) NSNumber *fixed_post;
@property(nonatomic, strong) NSNumber *has_photo;
@property(nonatomic, strong) NSNumber *is_favorite;
@property(nonatomic, strong) NSNumber *is_hidden_from_feed;
@property(nonatomic, strong) NSNumber *is_messages_blocked;
@property(nonatomic, strong) VKGroupLinks *links;
@property(nonatomic, strong) NSNumber *main_album_id;
@property(nonatomic, strong) NSNumber *main_section;
@property(nonatomic, strong) VKMarket *market;
@property(nonatomic, strong) NSNumber *member_status;
@property(nonatomic, strong) NSNumber *members_count;
@property(nonatomic, strong) VKGeoPlace *place;
@property(nonatomic, strong) NSString *public_date_label;
@property(nonatomic, strong) NSString *site;
@property(nonatomic, strong) NSNumber *start_date;
@property(nonatomic, strong) NSNumber *finish_date;
@property(nonatomic, strong) NSString *status;
@property(nonatomic, strong) NSString *trending;
@property(nonatomic, strong) NSNumber *verified;
@property(nonatomic, strong) NSNumber *wall;
@property(nonatomic, strong) NSString *wiki_page;

@end

@interface VKGroups : VKApiObjectArray<VKGroup*>

@end
