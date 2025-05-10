// Copyright 2022 Google LLC
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

#import "GoogleUtilities/Environment/Public/GoogleUtilities/GULNetworkInfo.h"

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>
#if __has_include("CoreTelephony/CTTelephonyNetworkInfo.h") && !TARGET_OS_MACCATALYST && \
                  !TARGET_OS_OSX && !TARGET_OS_TV && !TARGET_OS_WATCH
#define TARGET_HAS_MOBILE_CONNECTIVITY
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#endif

@implementation GULNetworkInfo

#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
+ (CTTelephonyNetworkInfo *)getNetworkInfo {
  static CTTelephonyNetworkInfo *networkInfo;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    networkInfo = [[CTTelephonyNetworkInfo alloc] init];
  });
  return networkInfo;
}
#endif

+ (GULNetworkType)getNetworkType {
  GULNetworkType networkType = GULNetworkTypeNone;

#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  static SCNetworkReachabilityRef reachabilityRef = 0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorSystemDefault, "google.com");
  });

  if (!reachabilityRef) {
    return GULNetworkTypeNone;
  }

  SCNetworkReachabilityFlags reachabilityFlags = 0;
  SCNetworkReachabilityGetFlags(reachabilityRef, &reachabilityFlags);

  // Parse the network flags to set the network type.
  if (reachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
    if (reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) {
      networkType = GULNetworkTypeMobile;
    } else {
      networkType = GULNetworkTypeWIFI;
    }
  }
#endif

  return networkType;
}

+ (NSString *)getNetworkRadioType {
#ifdef TARGET_HAS_MOBILE_CONNECTIVITY
  CTTelephonyNetworkInfo *networkInfo = [GULNetworkInfo getNetworkInfo];
  if (networkInfo.serviceCurrentRadioAccessTechnology.count) {
    return networkInfo.serviceCurrentRadioAccessTechnology.allValues[0] ?: @"";
  }
#endif
  return @"";
}

@end
