// Copyright 2021 Google LLC
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

#import "GoogleSignIn/Sources/Public/GoogleSignIn/GIDProfileData.h"

#import "GoogleSignIn/Sources/GIDProfileData_Private.h"

NS_ASSUME_NONNULL_BEGIN

// Key constants used for encode and decode.
static NSString *const kEmailKey = @"email";
static NSString *const kNameKey = @"name";
static NSString *const kGivenNameKey = @"given_name";
static NSString *const kFamilyNameKey = @"family_name";
static NSString *const kImageURLKey = @"image_url";
static NSString *const kOldImageURLStringKey = @"picture";

@implementation GIDProfileData {
  NSURL *_imageURL;
}

- (instancetype)initWithEmail:(NSString *)email
                         name:(NSString *)name
                    givenName:(nullable NSString *)givenName
                   familyName:(nullable NSString *)familyName
                     imageURL:(nullable NSURL *)imageURL {
  self = [super init];
  if (self) {
    _email = [email copy];
    _name = [name copy];
    _givenName = [givenName copy];
    _familyName = [familyName copy];
    _imageURL = [imageURL copy];
  }
  return self;
}

- (BOOL)hasImage {
  return _imageURL != nil;
}

- (nullable NSURL *)imageURLWithDimension:(NSUInteger)dimension {
  if (!_imageURL) {
    return nil;
  }
  NSURLComponents *url = [NSURLComponents componentsWithURL:_imageURL
                                    resolvingAgainstBaseURL:YES];
  if ([self isFIFEAvatarURL:_imageURL]) {
    // Remove any preexisting FIFE Avatar URL options
    NSError *error;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"=.*"
                                                  options:0
                                                    error:&error];
    url.path = [regex stringByReplacingMatchesInString:url.path
                                               options:0
                                                 range:NSMakeRange(0, url.path.length)
                                          withTemplate:@""];
    // Append our own FIFE Avatar URL options to the path
    url.path = [NSString stringWithFormat:@"%@=s%@", url.path, @(dimension)];
    return url.URL;
  } else {
    // Append our own FIFE image URL options query string, replacing any existing query string.
    NSURLQueryItem *queryItem =
        [NSURLQueryItem queryItemWithName:@"sz"
                                    value:[NSString stringWithFormat:@"%@", @(dimension)]];
    url.queryItems = @[ queryItem ];
    return url.URL;
  }
}

- (BOOL)isFIFEAvatarURL:(NSURL *)url {
  static NSString *const AvatarURLPattern =
      @"lh[3-6](-tt|-d[a-g,z]|-testonly)?\\.(google|googleusercontent)\\.[a-z]+\\/(a|a-)\\/";
  NSError *error;
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:AvatarURLPattern
                                                options:0
                                                  error:&error];
  if (!regex) {
    return NO;
  }

  NSUInteger matches = [regex numberOfMatchesInString:url.absoluteString
                                              options:0
                                                range:NSMakeRange(0, url.absoluteString.length)];

  if (matches) {
    return YES;
  }
  return NO;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _email = [decoder decodeObjectOfClass:[NSString class] forKey:kEmailKey];
    _name = [decoder decodeObjectOfClass:[NSString class] forKey:kNameKey];
    _givenName = [decoder decodeObjectOfClass:[NSString class] forKey:kGivenNameKey];
    _familyName = [decoder decodeObjectOfClass:[NSString class] forKey:kFamilyNameKey];
    _imageURL = [decoder decodeObjectOfClass:[NSURL class] forKey:kImageURLKey];

    // Check to see if this is an old archive, if so, try decoding the old image URL string key.
    if ([decoder containsValueForKey:kOldImageURLStringKey]) {
      _imageURL = [NSURL URLWithString:[decoder decodeObjectOfClass:[NSString class]
                                                             forKey:kOldImageURLStringKey]];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_email forKey:kEmailKey];
  [encoder encodeObject:_name forKey:kNameKey];
  [encoder encodeObject:_givenName forKey:kGivenNameKey];
  [encoder encodeObject:_familyName forKey:kFamilyNameKey];
  [encoder encodeObject:_imageURL forKey:kImageURLKey];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  // Instances of this class are immutable so we'll return self per NSCopying docs guidance.
  return self;
}

@end

NS_ASSUME_NONNULL_END
