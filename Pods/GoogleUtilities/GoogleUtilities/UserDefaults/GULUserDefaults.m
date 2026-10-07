// Copyright 2018 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GoogleUtilities/UserDefaults/Public/GoogleUtilities/GULUserDefaults.h"

#import "GoogleUtilities/Logger/Public/GoogleUtilities/GULLogger.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kGULLogFormat = @"I-GUL%06ld";

static GULLoggerService kGULLogUserDefaultsService = @"[GoogleUtilities/UserDefaults]";

typedef NS_ENUM(NSInteger, GULUDMessageCode) {
  GULUDMessageCodeInvalidKeyGet = 1,
  GULUDMessageCodeInvalidKeySet = 2,
  GULUDMessageCodeInvalidObjectSet = 3,
  GULUDMessageCodeSynchronizeFailed = 4,
};

@interface GULUserDefaults ()

@property(nonatomic, readonly) NSUserDefaults *userDefaults;

@end

@implementation GULUserDefaults

+ (GULUserDefaults *)standardUserDefaults {
  static GULUserDefaults *standardUserDefaults;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    standardUserDefaults = [[GULUserDefaults alloc] init];
  });
  return standardUserDefaults;
}

- (instancetype)init {
  return [self initWithSuiteName:nil];
}

- (instancetype)initWithSuiteName:(nullable NSString *)suiteName {
  self = [super init];

  NSString *name = [suiteName copy];

  if (self) {
    _userDefaults = name.length ? [[NSUserDefaults alloc] initWithSuiteName:name]
                                : [NSUserDefaults standardUserDefaults];
  }

  return self;
}

- (nullable id)objectForKey:(NSString *)defaultName {
  NSString *key = [defaultName copy];
  if (![key isKindOfClass:[NSString class]] || !key.length) {
    GULOSLogWarning(kGULLogSubsystem, @"<GoogleUtilities>", NO,
                    [NSString stringWithFormat:kGULLogFormat, (long)GULUDMessageCodeInvalidKeyGet],
                    @"Cannot get object for invalid user default key.");
    return nil;
  }

  return [self.userDefaults objectForKey:key];
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName {
  NSString *key = [defaultName copy];
  if (![key isKindOfClass:[NSString class]] || !key.length) {
    GULOSLogWarning(kGULLogSubsystem, kGULLogUserDefaultsService, NO,
                    [NSString stringWithFormat:kGULLogFormat, (long)GULUDMessageCodeInvalidKeySet],
                    @"Cannot set object for invalid user default key.");
    return;
  }
  if (!value) {
    [self.userDefaults removeObjectForKey:key];
    return;
  }
  BOOL isAcceptableValue =
      [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] ||
      [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] ||
      [value isKindOfClass:[NSDate class]] || [value isKindOfClass:[NSData class]];
  if (!isAcceptableValue) {
    GULOSLogWarning(
        kGULLogSubsystem, kGULLogUserDefaultsService, NO,
        [NSString stringWithFormat:kGULLogFormat, (long)GULUDMessageCodeInvalidObjectSet],
        @"Cannot set invalid object to user defaults. Must be a string, number, array, "
        @"dictionary, date, or data. Value: %@",
        value);
    return;
  }

  [self.userDefaults setObject:value forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
  [self setObject:nil forKey:key];
}

#pragma mark - Getters

- (NSInteger)integerForKey:(NSString *)defaultName {
  NSNumber *object = [self objectForKey:defaultName];
  return object.integerValue;
}

- (float)floatForKey:(NSString *)defaultName {
  NSNumber *object = [self objectForKey:defaultName];
  return object.floatValue;
}

- (double)doubleForKey:(NSString *)defaultName {
  NSNumber *object = [self objectForKey:defaultName];
  return object.doubleValue;
}

- (BOOL)boolForKey:(NSString *)defaultName {
  NSNumber *object = [self objectForKey:defaultName];
  return object.boolValue;
}

- (nullable NSString *)stringForKey:(NSString *)defaultName {
  return [self objectForKey:defaultName];
}

- (nullable NSArray *)arrayForKey:(NSString *)defaultName {
  return [self objectForKey:defaultName];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)defaultName {
  return [self objectForKey:defaultName];
}

#pragma mark - Setters

- (void)setInteger:(NSInteger)integer forKey:(NSString *)defaultName {
  [self setObject:@(integer) forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName {
  [self setObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)doubleNumber forKey:(NSString *)defaultName {
  [self setObject:@(doubleNumber) forKey:defaultName];
}

- (void)setBool:(BOOL)boolValue forKey:(NSString *)defaultName {
  [self setObject:@(boolValue) forKey:defaultName];
}

@end

NS_ASSUME_NONNULL_END
