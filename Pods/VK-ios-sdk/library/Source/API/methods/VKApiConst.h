//
//  VKApiConst.h
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

typedef NSString *VKDisplayType;
extern VKDisplayType const VK_DISPLAY_IOS;
extern VKDisplayType const VK_DISPLAY_MOBILE;
//Commons
extern NSString *const VK_ORIGINAL_CLIENT_BUNDLE;
extern NSString *const VK_ORIGINAL_HD_CLIENT_BUNDLE;
extern NSString *const VK_DEBUG_CLIENT_BUNDLE;
extern NSString *const VK_API_USER_ID;
extern NSString *const VK_API_USER_IDS;
extern NSString *const VK_API_FIELDS;
extern NSString *const VK_API_SORT;
extern NSString *const VK_API_OFFSET;
extern NSString *const VK_API_COUNT;
extern NSString *const VK_API_OWNER_ID;

//auth
extern NSString *const VK_API_LANG;
extern NSString *const VK_API_ACCESS_TOKEN;
extern NSString *const VK_API_SIG;

//get users
extern NSString *const VK_API_NAME_CASE;
extern NSString *const VK_API_ORDER;

//Get subscriptions
extern NSString *const VK_API_EXTENDED;

//Search
extern NSString *const VK_API_Q;
extern NSString *const VK_API_CITY;
extern NSString *const VK_API_COUNTRY;
extern NSString *const VK_API_HOMETOWN;
extern NSString *const VK_API_UNIVERSITY_COUNTRY;
extern NSString *const VK_API_UNIVERSITY;
extern NSString *const VK_API_UNIVERSITY_YEAR;
extern NSString *const VK_API_SEX;
extern NSString *const VK_API_STATUS;
extern NSString *const VK_API_AGE_FROM;
extern NSString *const VK_API_AGE_TO;
extern NSString *const VK_API_BIRTH_DAY;
extern NSString *const VK_API_BIRTH_MONTH;
extern NSString *const VK_API_BIRTH_YEAR;
extern NSString *const VK_API_ONLINE;
extern NSString *const VK_API_HAS_PHOTO;
extern NSString *const VK_API_SCHOOL_COUNTRY;
extern NSString *const VK_API_SCHOOL_CITY;
extern NSString *const VK_API_SCHOOL;
extern NSString *const VK_API_SCHOOL_YEAR;
extern NSString *const VK_API_RELIGION;
extern NSString *const VK_API_INTERESTS;
extern NSString *const VK_API_COMPANY;
extern NSString *const VK_API_POSITION;
extern NSString *const VK_API_GROUP_ID;
extern NSString *const VK_API_GROUP_IDS;

extern NSString *const VK_API_FRIENDS_ONLY;
extern NSString *const VK_API_FROM_GROUP;
extern NSString *const VK_API_MESSAGE;
extern NSString *const VK_API_ATTACHMENT;
extern NSString *const VK_API_ATTACHMENTS;
extern NSString *const VK_API_SERVICES;
extern NSString *const VK_API_SIGNED;
extern NSString *const VK_API_PUBLISH_DATE;
extern NSString *const VK_API_LAT;
extern NSString *const VK_API_LONG;
extern NSString *const VK_API_PLACE_ID;
extern NSString *const VK_API_POST_ID;

//Errors
extern NSString *const VK_API_ERROR_CODE;
extern NSString *const VK_API_ERROR_MSG;
extern NSString *const VK_API_ERROR_TEXT;
extern NSString *const VK_API_REQUEST_PARAMS;

//Captcha
extern NSString *const VK_API_CAPTCHA_IMG;
extern NSString *const VK_API_CAPTCHA_SID;
extern NSString *const VK_API_CAPTCHA_KEY;
extern NSString *const VK_API_REDIRECT_URI;

// Documents
extern NSString *const VK_API_DOC_ID;
extern NSString *const VK_API_ACCESS_KEY;
extern NSString *const VK_API_FILE;
extern NSString *const VK_API_TITLE;
extern NSString *const VK_API_TAGS;


//Photos
extern NSString *const VK_API_PHOTO;
extern NSString *const VK_API_ALBUM_ID;

//Events
extern NSString *const VKCaptchaAnsweredEvent;

//Enums
typedef NS_ENUM(NSInteger, VKProgressType) {
    VKProgressTypeUpload,
    VKProgressTypeDownload
};

