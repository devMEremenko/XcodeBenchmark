#import <Foundation/Foundation.h>

/// Debug values for testing geography.
typedef NS_ENUM(NSInteger, UMPDebugGeography) {
  UMPDebugGeographyDisabled = 0,  ///< Disable geography debugging.
  UMPDebugGeographyEEA = 1,       ///< Geography appears as in EEA for debug devices.
  UMPDebugGeographyNotEEA = 2,    ///< Geography appears as not in EEA for debug devices.
};

/// Overrides settings for debugging or testing.
@interface UMPDebugSettings : NSObject <NSCopying>

/// Array of device identifier strings. Debug features are enabled for devices with these
/// identifiers. Debug features are always enabled for simulators.
@property(nonatomic, nullable) NSArray<NSString *> *testDeviceIdentifiers;

/// Debug geography.
@property(nonatomic) UMPDebugGeography geography;

@end
