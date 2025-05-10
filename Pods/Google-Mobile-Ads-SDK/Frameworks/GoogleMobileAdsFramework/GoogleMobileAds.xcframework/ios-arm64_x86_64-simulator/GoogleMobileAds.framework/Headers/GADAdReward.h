//
//  GADAdReward.h
//  Google Mobile Ads SDK
//
//  Copyright 2015 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// A block to be executed when the user earns a reward.
typedef void (^GADUserDidEarnRewardHandler)(void);

/// Ad reward information.
@interface GADAdReward : NSObject

/// Type of the reward.
@property(nonatomic, readonly, nonnull) NSString *type;

/// Amount rewarded to the user.
@property(nonatomic, readonly, nonnull) NSDecimalNumber *amount;

/// Returns an initialized GADAdReward with the provided reward type and reward amount.
- (nonnull instancetype)initWithRewardType:(nullable NSString *)rewardType
                              rewardAmount:(nullable NSDecimalNumber *)rewardAmount
    NS_DESIGNATED_INITIALIZER;

@end
