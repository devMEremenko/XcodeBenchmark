/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <UserNotifications/UserNotifications.h>

#import "FirebaseMessaging/Sources/FIRMessagingContextManagerService.h"

#import "FirebaseMessaging/Sources/FIRMessagingDefines.h"
#import "FirebaseMessaging/Sources/FIRMessagingLogger.h"
#import "FirebaseMessaging/Sources/FIRMessagingUtilities.h"

#import <GoogleUtilities/GULAppDelegateSwizzler.h>

#define kFIRMessagingContextManagerPrefix @"gcm."
#define kFIRMessagingContextManagerPrefixKey @"google.c.cm."
#define kFIRMessagingContextManagerNotificationKeyPrefix @"gcm.notification."

static NSString *const kLogTag = @"FIRMessagingAnalytics";

static NSString *const kLocalTimeFormatString = @"yyyy-MM-dd HH:mm:ss";

static NSString *const kContextManagerPrefixKey = kFIRMessagingContextManagerPrefixKey;

// Local timed messages (format yyyy-mm-dd HH:mm:ss)
NSString *const kFIRMessagingContextManagerLocalTimeStart =
    kFIRMessagingContextManagerPrefixKey @"lt_start";
NSString *const kFIRMessagingContextManagerLocalTimeEnd =
    kFIRMessagingContextManagerPrefixKey @"lt_end";

// Local Notification Params
NSString *const kFIRMessagingContextManagerBodyKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"body";
NSString *const kFIRMessagingContextManagerTitleKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"title";
NSString *const kFIRMessagingContextManagerBadgeKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"badge";
NSString *const kFIRMessagingContextManagerCategoryKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"click_action";
NSString *const kFIRMessagingContextManagerSoundKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"sound";
NSString *const kFIRMessagingContextManagerContentAvailableKey =
    kFIRMessagingContextManagerNotificationKeyPrefix @"content-available";
static NSString *const kFIRMessagingID = kFIRMessagingContextManagerPrefix @"message_id";
static NSString *const kFIRMessagingAPNSPayloadKey = @"aps";

typedef NS_ENUM(NSUInteger, FIRMessagingContextManagerMessageType) {
  FIRMessagingContextManagerMessageTypeNone,
  FIRMessagingContextManagerMessageTypeLocalTime,
};

@implementation FIRMessagingContextManagerService

+ (BOOL)isContextManagerMessage:(NSDictionary *)message {
  // For now we only support local time in ContextManager.
  if (![message[kFIRMessagingContextManagerLocalTimeStart] length]) {
    FIRMessagingLoggerDebug(
        kFIRMessagingMessageCodeContextManagerService000,
        @"Received message missing local start time, not a contextual message.");
    return NO;
  }

  return YES;
}

+ (BOOL)handleContextManagerMessage:(NSDictionary *)message {
  NSString *startTimeString = message[kFIRMessagingContextManagerLocalTimeStart];
  if (startTimeString.length) {
    FIRMessagingLoggerDebug(kFIRMessagingMessageCodeContextManagerService001,
                            @"%@ Received context manager message with local time %@", kLogTag,
                            startTimeString);
    return [self handleContextManagerLocalTimeMessage:message];
  }

  return NO;
}

+ (BOOL)handleContextManagerLocalTimeMessage:(NSDictionary *)message {
  NSString *startTimeString = message[kFIRMessagingContextManagerLocalTimeStart];
  if (!startTimeString) {
    FIRMessagingLoggerError(kFIRMessagingMessageCodeContextManagerService002,
                            @"Invalid local start date format %@. Message dropped",
                            startTimeString);
    return NO;
  }
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
  [dateFormatter setDateFormat:kLocalTimeFormatString];
  NSDate *startDate = [dateFormatter dateFromString:startTimeString];
  NSDate *currentDate = [NSDate date];

  if ([currentDate compare:startDate] == NSOrderedAscending) {
    [self scheduleLocalNotificationForMessage:message atDate:startDate];
  } else {
    // check end time has not passed
    NSString *endTimeString = message[kFIRMessagingContextManagerLocalTimeEnd];
    if (!endTimeString) {
      FIRMessagingLoggerInfo(
          kFIRMessagingMessageCodeContextManagerService003,
          @"No end date specified for message, start date elapsed. Message dropped.");
      return YES;
    }

    NSDate *endDate = [dateFormatter dateFromString:endTimeString];
    if (!endTimeString) {
      FIRMessagingLoggerError(kFIRMessagingMessageCodeContextManagerService004,
                              @"Invalid local end date format %@. Message dropped", endTimeString);
      return NO;
    }

    if ([endDate compare:currentDate] == NSOrderedAscending) {
      // end date has already passed drop the message
      FIRMessagingLoggerInfo(kFIRMessagingMessageCodeContextManagerService005,
                             @"End date %@ has already passed. Message dropped.", endTimeString);
      return YES;
    }

    // schedule message right now (buffer 10s)
    [self scheduleLocalNotificationForMessage:message
                                       atDate:[currentDate dateByAddingTimeInterval:10]];
  }
  return YES;
}

+ (void)scheduleiOS10LocalNotificationForMessage:(NSDictionary *)message
                                          atDate:(NSDate *)date
    API_AVAILABLE(macosx(10.14), ios(10.0), watchos(3.0), tvos(10.0)) {
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                        NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
  NSDateComponents *dateComponents = [calendar components:(NSCalendarUnit)unit fromDate:date];
  UNCalendarNotificationTrigger *trigger =
      [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];

  UNMutableNotificationContent *content = [self contentFromContextualMessage:message];
  NSString *identifier = message[kFIRMessagingID];
  if (!identifier) {
    identifier = [NSUUID UUID].UUIDString;
  }

  UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                        content:content
                                                                        trigger:trigger];
  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  [center
      addNotificationRequest:request
       withCompletionHandler:^(NSError *_Nullable error) {
         if (error) {
           FIRMessagingLoggerError(kFIRMessagingMessageCodeContextManagerServiceFailedLocalSchedule,
                                   @"Failed scheduling local timezone notification: %@.", error);
         }
       }];
}

+ (UNMutableNotificationContent *)contentFromContextualMessage:(NSDictionary *)message
    API_AVAILABLE(macosx(10.14), ios(10.0), watchos(3.0), tvos(10.0)) {
  UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
  NSDictionary *apsDictionary = message;

  // Badge is universal
  if (apsDictionary[kFIRMessagingContextManagerBadgeKey]) {
    content.badge = apsDictionary[kFIRMessagingContextManagerBadgeKey];
  }
#if !TARGET_OS_TV
  // The following fields are not available on tvOS
  if ([apsDictionary[kFIRMessagingContextManagerBodyKey] length]) {
    content.body = apsDictionary[kFIRMessagingContextManagerBodyKey];
  }

  if ([apsDictionary[kFIRMessagingContextManagerTitleKey] length]) {
    content.title = apsDictionary[kFIRMessagingContextManagerTitleKey];
  }

  if (apsDictionary[kFIRMessagingContextManagerSoundKey]) {
#if !TARGET_OS_WATCH
    // UNNotificationSound soundNamded: is not available in watchOS
    content.sound =
        [UNNotificationSound soundNamed:apsDictionary[kFIRMessagingContextManagerSoundKey]];
#else   // !TARGET_OS_WATCH
    content.sound = [UNNotificationSound defaultSound];
#endif  // !TARGET_OS_WATCH
  }

  if (apsDictionary[kFIRMessagingContextManagerCategoryKey]) {
    content.categoryIdentifier = apsDictionary[kFIRMessagingContextManagerCategoryKey];
  }

  NSDictionary *userInfo = [self parseDataFromMessage:message];
  if (userInfo.count) {
    content.userInfo = userInfo;
  }
#endif  // !TARGET_OS_TV
  return content;
}

+ (void)scheduleLocalNotificationForMessage:(NSDictionary *)message atDate:(NSDate *)date {
  if (@available(macOS 10.14, *)) {
    [self scheduleiOS10LocalNotificationForMessage:message atDate:date];
    return;
  }
}

+ (NSDictionary *)parseDataFromMessage:(NSDictionary *)message {
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  for (NSObject<NSCopying> *key in message) {
    if ([key isKindOfClass:[NSString class]]) {
      NSString *keyString = (NSString *)key;
      if ([keyString isEqualToString:kFIRMessagingContextManagerContentAvailableKey]) {
        continue;
      } else if ([keyString hasPrefix:kContextManagerPrefixKey]) {
        continue;
      } else if ([keyString isEqualToString:kFIRMessagingAPNSPayloadKey]) {
        // Local timezone message is scheduled with FCM payload. APNS payload with
        // content_available should be ignored and not passed to the scheduled
        // messages.
        continue;
      }
    }
    data[[key copy]] = message[key];
  }
  return [data copy];
}

@end
