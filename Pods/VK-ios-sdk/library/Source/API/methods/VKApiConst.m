//
//  VKApiConst.m
//  VKSdk
//
//  Created by Roman Truba on 27.04.15.
//  Copyright (c) 2015 VK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKApiConst.h"

VKDisplayType const VK_DISPLAY_IOS = @"ios";
VKDisplayType const VK_DISPLAY_MOBILE = @"mobile";

NSString *const VK_ORIGINAL_CLIENT_BUNDLE = @"com.vk.vkclient";
NSString *const VK_ORIGINAL_HD_CLIENT_BUNDLE = @"com.vk.vkhd";
NSString *const VK_DEBUG_CLIENT_BUNDLE = @"com.vk.odnoletkov.client";
NSString *const VK_API_USER_ID = @"user_id";
NSString *const VK_API_USER_IDS = @"user_ids";
NSString *const VK_API_FIELDS = @"fields";
NSString *const VK_API_SORT = @"sort";
NSString *const VK_API_OFFSET = @"offset";
NSString *const VK_API_COUNT = @"count";
NSString *const VK_API_OWNER_ID = @"owner_id";

//auth
NSString *const VK_API_LANG = @"lang";
NSString *const VK_API_ACCESS_TOKEN = @"access_token";
NSString *const VK_API_SIG = @"sig";

//get users
NSString *const VK_API_NAME_CASE = @"name_case";
NSString *const VK_API_ORDER = @"order";

//Get subscriptions
NSString *const VK_API_EXTENDED = @"extended";

//Search
NSString *const VK_API_Q = @"q";
NSString *const VK_API_CITY = @"city";
NSString *const VK_API_COUNTRY = @"country";
NSString *const VK_API_HOMETOWN = @"hometown";
NSString *const VK_API_UNIVERSITY_COUNTRY = @"university_country";
NSString *const VK_API_UNIVERSITY = @"university";
NSString *const VK_API_UNIVERSITY_YEAR = @"university_year";
NSString *const VK_API_SEX = @"sex";
NSString *const VK_API_STATUS = @"status";
NSString *const VK_API_AGE_FROM = @"age_from";
NSString *const VK_API_AGE_TO = @"age_to";
NSString *const VK_API_BIRTH_DAY = @"birth_day";
NSString *const VK_API_BIRTH_MONTH = @"birth_month";
NSString *const VK_API_BIRTH_YEAR = @"birth_year";
NSString *const VK_API_ONLINE = @"online";
NSString *const VK_API_HAS_PHOTO = @"has_photo";
NSString *const VK_API_SCHOOL_COUNTRY = @"school_country";
NSString *const VK_API_SCHOOL_CITY = @"school_city";
NSString *const VK_API_SCHOOL = @"school";
NSString *const VK_API_SCHOOL_YEAR = @"school_year";
NSString *const VK_API_RELIGION = @"religion";
NSString *const VK_API_INTERESTS = @"interests";
NSString *const VK_API_COMPANY = @"company";
NSString *const VK_API_POSITION = @"position";
NSString *const VK_API_GROUP_ID = @"group_id";
NSString *const VK_API_GROUP_IDS = @"group_ids";

NSString *const VK_API_FRIENDS_ONLY = @"friends_only";
NSString *const VK_API_FROM_GROUP = @"from_group";
NSString *const VK_API_MESSAGE = @"message";
NSString *const VK_API_ATTACHMENT = @"attachment";
NSString *const VK_API_ATTACHMENTS = @"attachments";
NSString *const VK_API_SERVICES = @"services";
NSString *const VK_API_SIGNED = @"signed";
NSString *const VK_API_PUBLISH_DATE = @"publish_date";
NSString *const VK_API_LAT = @"lat";
NSString *const VK_API_LONG = @"long";
NSString *const VK_API_PLACE_ID = @"place_id";
NSString *const VK_API_POST_ID = @"post_id";

//Errors
NSString *const VK_API_ERROR_CODE = @"error_code";
NSString *const VK_API_ERROR_MSG = @"error_msg";
NSString *const VK_API_ERROR_TEXT = @"error_text";
NSString *const VK_API_REQUEST_PARAMS = @"request_params";

//Captcha
NSString *const VK_API_CAPTCHA_IMG = @"captcha_img";
NSString *const VK_API_CAPTCHA_SID = @"captcha_sid";
NSString *const VK_API_CAPTCHA_KEY = @"captcha_key";
NSString *const VK_API_REDIRECT_URI = @"redirect_uri";

//Documents
NSString *const VK_API_DOC_ID = @"doc_id";
NSString *const VK_API_ACCESS_KEY = @"access_key";
NSString *const VK_API_FILE = @"file";
NSString *const VK_API_TITLE = @"title";
NSString *const VK_API_TAGS = @"tags";

//Photos
NSString *const VK_API_PHOTO = @"photo";
NSString *const VK_API_ALBUM_ID = @"album_id";

//Events
NSString *const VKCaptchaAnsweredEvent = @"VKCaptchaAnsweredEvent";
