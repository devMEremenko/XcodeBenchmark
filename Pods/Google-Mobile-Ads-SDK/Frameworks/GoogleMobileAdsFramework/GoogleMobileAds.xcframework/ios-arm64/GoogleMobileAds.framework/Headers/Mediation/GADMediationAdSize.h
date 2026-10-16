//
//  GADMediationAdSize.h
//  Google Mobile Ads SDK
//
//  Copyright 2019 Google. All rights reserved.
//

#import <GoogleMobileAds/GADAdSize.h>

/// Returns the closest valid ad size from possibleAdSizes as compared to |original|. The selected
/// size must be smaller than or equal in size to the original. The selected size must also be
/// within a configurable fraction of the width and height of the original. If no valid size exists,
/// returns GADAdSizeInvalid.
FOUNDATION_EXPORT GADAdSize
GADClosestValidSizeForAdSizes(GADAdSize original, NSArray<NSValue *> *_Nonnull possibleAdSizes);
