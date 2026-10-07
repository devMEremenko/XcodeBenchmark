//
//  VKUser.h
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
#import "VKApiObject.h"
#import "VKApiObjectArray.h"
#import "VKCounters.h"
#import "VKPhoto.h"
#import "VKSchool.h"
#import "VKUniversity.h"
#import "VKRelative.h"

@interface VKGeoObject : VKApiObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *title;
@end

@interface VKCity : VKGeoObject
@end

@interface VKCountry : VKGeoObject
@end

/**
 * User personal information (field 'personal')
 */
@interface VKPersonal : VKObject
@property(nonatomic, strong) NSNumber *political;
@property(nonatomic, strong) NSArray *langs;
@property(nonatomic, strong) NSString *religion;
@property(nonatomic, strong) NSString *inspired_by;
@property(nonatomic, strong) NSNumber *people_main;
@property(nonatomic, strong) NSNumber *life_main;
@property(nonatomic, strong) NSNumber *smoking;
@property(nonatomic, strong) NSNumber *alcohol;
@end

/**
 * User last seen information (field 'last_seen')
 */
@interface VKLastSeen : VKApiObject
@property(nonatomic, strong) NSNumber *time;
@property(nonatomic, strong) NSNumber *platform;
@end

/**
 * Information about connected services by user (field 'exports')
 */
@interface VKExports : VKApiObject
@property(nonatomic, strong) NSNumber *twitter;
@property(nonatomic, strong) NSNumber *facebook;
@property(nonatomic, strong) NSNumber *livejournal;
@property(nonatomic, strong) NSNumber *instagram;
@end

/**
 Information about user's career (field 'career')
 */
@interface VKCareer : VKApiObject
@property(nonatomic, strong) NSNumber *group_id;
@property(nonatomic, strong) NSString *company;
@property(nonatomic, strong) NSNumber *country_id;
@property(nonatomic, strong) NSNumber *city_id;
@property(nonatomic, strong) NSString *city_name;
@property(nonatomic, strong) NSNumber *from;
@property(nonatomic, strong) NSNumber *until;
@property(nonatomic, strong) NSString *position;
@end

/**
 Cropped user photo.
*/
@interface VKCrop: VKApiObject
@property(nonatomic, strong) NSNumber *x;
@property(nonatomic, strong) NSNumber *y;
@property(nonatomic, strong) NSNumber *x2;
@property(nonatomic, strong) NSNumber *y2;
@end

/**
 Data about points used for cropping of profile and preview user photos.
*/
@interface VKCropPhoto : VKApiObject
@property(nonatomic, strong) VKPhoto *photo;
@property(nonatomic, strong) VKCrop *crop;
@property(nonatomic, strong) VKCrop *rect;
@end

/**
 Information about user's military service.
*/
@interface VKMilitary: VKApiObject
@property(nonatomic, strong) NSString *unit;
@property(nonatomic, strong) NSNumber *unit_id;
@property(nonatomic, strong) NSNumber *country_id;
@property(nonatomic, strong) NSNumber *from;
@property(nonatomic, strong) NSNumber *until;
@end

/**
 User's occupation
*/
@interface VKOccupation: VKApiObject
@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *name;
@end

/**
 User type of VK API. See descriptions here https://vk.com/dev/fields
 */
@interface VKUser : VKApiObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *first_name;
@property(nonatomic, strong) NSString *last_name;
@property(nonatomic, strong) NSString *deactivated;
@property(nonatomic, strong) NSNumber *is_closed;
@property(nonatomic, strong) NSNumber *can_access_closed;

@property(nonatomic, strong) NSString *about;
@property(nonatomic, strong) NSString *activities;
@property(nonatomic, strong) NSString *bdate;
@property(nonatomic, assign) BOOL blacklisted;
@property(nonatomic, assign) BOOL blacklisted_by_me;
@property(nonatomic, strong) NSString *books;
@property(nonatomic, assign) BOOL can_post;
@property(nonatomic, assign) BOOL can_see_all_posts;
@property(nonatomic, assign) BOOL can_see_audio;
@property(nonatomic, assign) BOOL can_see_friend_request;
@property(nonatomic, assign) BOOL can_write_private_message;
@property(nonatomic, strong) VKCareer *career;
@property(nonatomic, strong) VKCity *city;
@property(nonatomic, strong) NSNumber *common_count;
@property(nonatomic, strong) VKCounters *counters;
@property(nonatomic, strong) VKCountry *country;
@property(nonatomic, strong) VKCropPhoto *crop_photo;
@property(nonatomic, strong) NSString *domain;
@property(nonatomic, strong) VKExports *exports;

@property(nonatomic, strong) NSString *first_name_nom;
@property(nonatomic, strong) NSString *first_name_gen;
@property(nonatomic, strong) NSString *first_name_dat;
@property(nonatomic, strong) NSString *first_name_acc;
@property(nonatomic, strong) NSString *first_name_ins;
@property(nonatomic, strong) NSString *first_name_abl;

@property(nonatomic, strong) NSNumber *followers_count;
@property(nonatomic, strong) NSNumber *friend_status;
@property(nonatomic, strong) NSString *games;
@property(nonatomic, assign) BOOL has_mobile;
@property(nonatomic, assign) BOOL has_photo;
@property(nonatomic, strong) NSString *home_phone;
@property(nonatomic, strong) NSString *home_town;
@property(nonatomic, strong) NSString *interests;
@property(nonatomic, assign) BOOL is_favorite;
@property(nonatomic, assign) BOOL is_friend;
@property(nonatomic, assign) BOOL is_hidden_from_feed;

@property(nonatomic, strong) NSString *last_name_nom;
@property(nonatomic, strong) NSString *last_name_gen;
@property(nonatomic, strong) NSString *last_name_dat;
@property(nonatomic, strong) NSString *last_name_acc;
@property(nonatomic, strong) NSString *last_name_ins;
@property(nonatomic, strong) NSString *last_name_abl;

@property(nonatomic, strong) VKLastSeen *last_seen;
@property(nonatomic, strong) NSString *lists;
@property(nonatomic, strong) NSString *maiden_name;
@property(nonatomic, strong) VKMilitary *military;
@property(nonatomic, strong) NSString *mobile_phone;
@property(nonatomic, strong) NSString *movies;
@property(nonatomic, strong) NSString *music;
@property(nonatomic, strong) NSString *nickname;
@property(nonatomic, strong) VKOccupation *occupation;
@property(nonatomic, assign) BOOL online;
@property(nonatomic, assign) BOOL online_mobile;
@property(nonatomic, strong) NSNumber *online_app;
@property(nonatomic, strong) VKPersonal *personal;

@property(nonatomic, strong) NSString *photo_50;
@property(nonatomic, strong) NSString *photo_100;
@property(nonatomic, strong) NSString *photo_200;
@property(nonatomic, strong) NSString *photo_200_orig;
@property(nonatomic, strong) NSString *photo_400_orig;
@property(nonatomic, strong) NSString *photo_id;
@property(nonatomic, strong) NSString *photo_max;
@property(nonatomic, strong) NSString *photo_max_orig;

@property(nonatomic, strong) NSString *quoutes;
@property(nonatomic, strong) VKRelativities *relatives;
@property(nonatomic, strong) NSNumber *relation;
@property(nonatomic, strong) VKSchools *schools;
@property(nonatomic, strong) NSString *screen_name;
@property(nonatomic, strong) NSNumber *sex;
@property(nonatomic, strong) NSString *site;
@property(nonatomic, strong) NSString *status;
@property(nonatomic, strong) NSNumber *timezone;
@property(nonatomic, assign) BOOL trending;
@property(nonatomic, strong) NSString *tv;

@property(nonatomic, strong) NSNumber *university;
@property(nonatomic, strong) VKUniversities *universities;
@property(nonatomic, strong) NSString *university_name;
@property(nonatomic, strong) NSNumber *faculty;
@property(nonatomic, strong) NSString *faculty_name;
@property(nonatomic, strong) NSNumber *graduation;

@property(nonatomic, assign) BOOL verified;
@property(nonatomic, strong) NSString *wall_default;

@property(nonatomic, strong) NSString *skype;
@property(nonatomic, strong) NSString *facebook;
@property(nonatomic, strong) NSString *twitter;
@property(nonatomic, strong) NSString *livejournal;
@property(nonatomic, strong) NSString *instagram;

@end

/**
Array of API users
*/
@interface VKUsersArray : VKApiObjectArray<VKUser*>
@end
