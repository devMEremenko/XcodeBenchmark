// Copyright 2023 Google LLC
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

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORProductData.h"

@implementation GDTCORProductData

- (instancetype)initWithProductID:(int32_t)productID {
  self = [super init];
  if (self) {
    _productID = productID;
  }
  return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
  return [[[self class] alloc] initWithProductID:self.productID];
}

#pragma mark - Equality

- (BOOL)isEqualToProductData:(GDTCORProductData *)otherProductData {
  return self.productID == otherProductData.productID;
}

- (BOOL)isEqual:(nullable id)object {
  if (object == nil) {
    return NO;
  }

  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self isEqualToProductData:(GDTCORProductData *)object];
}

- (NSUInteger)hash {
  return self.productID;
}

#pragma mark - NSSecureCoding

/// NSCoding key for `productID` property.
static NSString *kProductIDKey = @"GDTCORProductDataProductIDKey";

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  int32_t productID = [coder decodeInt32ForKey:kProductIDKey];
  return [self initWithProductID:productID];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeInt32:self.productID forKey:kProductIDKey];
}

@end
