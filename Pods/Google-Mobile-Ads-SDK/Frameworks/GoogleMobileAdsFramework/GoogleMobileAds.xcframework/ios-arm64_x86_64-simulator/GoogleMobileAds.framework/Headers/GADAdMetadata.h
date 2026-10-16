//
//  GADAdMetadata.h
//  Google Mobile Ads SDK
//
//  Copyright 2017 Google LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Ad metadata key type.
typedef NSString *GADAdMetadataKey NS_TYPED_ENUM;

@protocol GADAdMetadataDelegate;

/// Protocol for ads that provide ad metadata.
@protocol GADAdMetadataProvider <NSObject>

/// The ad's metadata. Use adMetadataDelegate to receive ad metadata change messages.
@property(nonatomic, readonly, nullable) NSDictionary<GADAdMetadataKey, id> *adMetadata;

/// Delegate for receiving ad metadata changes.
@property(nonatomic, weak, nullable) id<GADAdMetadataDelegate> adMetadataDelegate;

@end

/// Delegate protocol for receiving ad metadata change messages from a GADAdMetadataProvider.
@protocol GADAdMetadataDelegate <NSObject>

/// Tells the delegate that the ad's metadata changed. Called when an ad loads and when a loaded
/// ad's metadata changes.
- (void)adMetadataDidChange:(nonnull id<GADAdMetadataProvider>)ad;

@end
