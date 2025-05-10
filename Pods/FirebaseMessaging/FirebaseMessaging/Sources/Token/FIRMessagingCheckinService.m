/*
 * Copyright 2019 Google
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

#import "FirebaseMessaging/Sources/Token/FIRMessagingCheckinService.h"

#import <GoogleUtilities/GULAppEnvironmentUtil.h>
#import "FirebaseMessaging/Sources/FIRMessagingDefines.h"
#import "FirebaseMessaging/Sources/FIRMessagingLogger.h"
#import "FirebaseMessaging/Sources/FIRMessagingUtilities.h"
#import "FirebaseMessaging/Sources/NSError+FIRMessaging.h"
#import "FirebaseMessaging/Sources/Token/FIRMessagingAuthService.h"
#import "FirebaseMessaging/Sources/Token/FIRMessagingCheckinPreferences.h"

static NSString *const kDeviceCheckinURL = @"https://device-provisioning.googleapis.com/checkin";

// keys in Checkin preferences
NSString *const kFIRMessagingDeviceAuthIdKey = @"GMSInstanceIDDeviceAuthIdKey";
NSString *const kFIRMessagingSecretTokenKey = @"GMSInstanceIDSecretTokenKey";
NSString *const kFIRMessagingDigestStringKey = @"GMSInstanceIDDigestKey";
NSString *const kFIRMessagingLastCheckinTimeKey = @"GMSInstanceIDLastCheckinTimestampKey";
NSString *const kFIRMessagingVersionInfoStringKey = @"GMSInstanceIDVersionInfo";
NSString *const kFIRMessagingGServicesDictionaryKey = @"GMSInstanceIDGServicesData";
NSString *const kFIRMessagingDeviceDataVersionKey = @"GMSInstanceIDDeviceDataVersion";

static NSUInteger const kCheckinType = 2;  // DeviceType IOS in l/w/a/_checkin.proto
static NSUInteger const kCheckinVersion = 2;
static NSUInteger const kFragment = 0;

@interface FIRMessagingCheckinService ()

@property(nonatomic, readwrite, strong) NSURLSession *session;

@end

@implementation FIRMessagingCheckinService

- (instancetype)init {
  self = [super init];
  if (self) {
    // Create an URLSession once, even though checkin should happen about once a day
    NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
    config.timeoutIntervalForResource = 60.0f;  // 1 minute
    config.allowsCellularAccess = YES;

    self.session = [NSURLSession sessionWithConfiguration:config];
    self.session.sessionDescription = @"com.google.iid-checkin";
  }
  return self;
}
- (void)dealloc {
  [self.session invalidateAndCancel];
}

- (void)checkinWithExistingCheckin:(FIRMessagingCheckinPreferences *)existingCheckin
                        completion:(FIRMessagingDeviceCheckinCompletion)completion {
  if (self.session == nil) {
    FIRMessagingLoggerError(kFIRMessagingMessageCodeService005,
                            @"Inconsistent state: NSURLSession has been invalidated");
    NSError *error =
        [NSError messagingErrorWithCode:kFIRMessagingErrorCodeRegistrarFailedToCheckIn
                          failureReason:@"Failed to checkin. NSURLSession is invalid."];
    if (completion) {
      completion(nil, error);
    }
    return;
  }
  NSURL *url = [NSURL URLWithString:kDeviceCheckinURL];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
  NSDictionary *checkinParameters = [self checkinParametersWithExistingCheckin:existingCheckin];
  NSData *checkinData = [NSJSONSerialization dataWithJSONObject:checkinParameters
                                                        options:0
                                                          error:nil];
  request.HTTPMethod = @"POST";
  request.HTTPBody = checkinData;

  void (^handler)(NSData *, NSURLResponse *, NSError *) =
      ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
          FIRMessagingLoggerDebug(kFIRMessagingMessageCodeService000,
                                  @"Device checkin HTTP fetch error. Error Code: %ld",
                                  (long)error.code);
          if (completion) {
            completion(nil, error);
          }
          return;
        }

        NSError *serializationError = nil;
        NSDictionary *dataResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:&serializationError];
        if (serializationError) {
          FIRMessagingLoggerDebug(kFIRMessagingMessageCodeService001,
                                  @"Error serializing json object. Error Code: %ld",
                                  (long)serializationError.code);
          if (completion) {
            completion(nil, serializationError);
          }
          return;
        }

        NSString *deviceAuthID = [dataResponse[@"android_id"] stringValue];
        NSString *secretToken = [dataResponse[@"security_token"] stringValue];
        if ([deviceAuthID length] == 0) {
          NSError *error = [NSError messagingErrorWithCode:kFIRMessagingErrorCodeInvalidRequest
                                             failureReason:@"Invalid device auth ID."];
          if (completion) {
            completion(nil, error);
          }
          return;
        }

        int64_t lastCheckinTimestampMillis = [dataResponse[@"time_msec"] longLongValue];
        int64_t currentTimestampMillis = FIRMessagingCurrentTimestampInMilliseconds();
        // Somehow the server clock gets out of sync with the device clock.
        // Reset the last checkin timestamp in case this happens.
        if (lastCheckinTimestampMillis > currentTimestampMillis) {
          FIRMessagingLoggerDebug(
              kFIRMessagingMessageCodeService002, @"Invalid last checkin timestamp %@ in future.",
              [NSDate dateWithTimeIntervalSince1970:lastCheckinTimestampMillis / 1000.0]);
          lastCheckinTimestampMillis = currentTimestampMillis;
        }

        NSString *deviceDataVersionInfo = dataResponse[@"device_data_version_info"] ?: @"";
        NSString *digest = dataResponse[@"digest"] ?: @"";

        FIRMessagingLoggerDebug(kFIRMessagingMessageCodeService003,
                                @"Checkin successful with authId: %@, "
                                @"digest: %@, "
                                @"lastCheckinTimestamp: %lld",
                                deviceAuthID, digest, lastCheckinTimestampMillis);

        NSString *versionInfo = dataResponse[@"version_info"] ?: @"";
        NSMutableDictionary *gservicesData = [NSMutableDictionary dictionary];

        // Read gServices data.
        NSArray *flatSettings = dataResponse[@"setting"];
        for (NSDictionary *dict in flatSettings) {
          if (dict[@"name"] && dict[@"value"]) {
            gservicesData[dict[@"name"]] = dict[@"value"];
          } else {
            FIRMessagingLoggerDebug(kFIRMessagingInvalidSettingResponse,
                                    @"Invalid setting in checkin response: (%@: %@)", dict[@"name"],
                                    dict[@"value"]);
          }
        }

        FIRMessagingCheckinPreferences *checkinPreferences =
            [[FIRMessagingCheckinPreferences alloc] initWithDeviceID:deviceAuthID
                                                         secretToken:secretToken];
        NSDictionary *preferences = @{
          kFIRMessagingDigestStringKey : digest,
          kFIRMessagingVersionInfoStringKey : versionInfo,
          kFIRMessagingLastCheckinTimeKey : @(lastCheckinTimestampMillis),
          kFIRMessagingGServicesDictionaryKey : gservicesData,
          kFIRMessagingDeviceDataVersionKey : deviceDataVersionInfo,
        };
        [checkinPreferences updateWithCheckinPlistContents:preferences];
        if (completion) {
          completion(checkinPreferences, nil);
        }
      };

  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
  [task resume];
}

- (void)stopFetching {
  [self.session invalidateAndCancel];
  // The session cannot be reused after invalidation. Dispose it to prevent accident reusing.
  self.session = nil;
}

#pragma mark - Private

- (NSDictionary *)checkinParametersWithExistingCheckin:
    (nullable FIRMessagingCheckinPreferences *)checkinPreferences {
  NSString *deviceModel = [GULAppEnvironmentUtil deviceModel];
  NSString *systemVersion = [GULAppEnvironmentUtil systemVersion];
  NSString *osVersion = [NSString stringWithFormat:@"IOS_%@", systemVersion];

  // Get locale from GCM if GCM exists else use system API.
  NSString *locale = FIRMessagingCurrentLocale();

  NSInteger userNumber = 0;        // Multi Profile may change this.
  NSInteger userSerialNumber = 0;  // Multi Profile may change this

  NSString *timeZone = [NSTimeZone localTimeZone].name;
  int64_t lastCheckingTimestampMillis = checkinPreferences.lastCheckinTimestampMillis;

  NSDictionary *checkinParameters = @{
    @"checkin" : @{
      @"iosbuild" : @{@"model" : deviceModel, @"os_version" : osVersion},
      @"type" : @(kCheckinType),
      @"user_number" : @(userNumber),
      @"last_checkin_msec" : @(lastCheckingTimestampMillis),
    },
    @"fragment" : @(kFragment),
    @"locale" : locale,
    @"version" : @(kCheckinVersion),
    @"digest" : checkinPreferences.digest ?: @"",
    @"time_zone" : timeZone,
    @"user_serial_number" : @(userSerialNumber),
    @"id" : @([checkinPreferences.deviceID longLongValue]),
    @"security_token" : @([checkinPreferences.secretToken longLongValue]),
  };

  FIRMessagingLoggerDebug(kFIRMessagingMessageCodeService006, @"Checkin parameters: %@",
                          checkinParameters);
  return checkinParameters;
}

@end
