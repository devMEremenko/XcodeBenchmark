#import <Foundation/Foundation.h>

/// Debug values for testing geography.
typedef NS_ENUM(NSInteger, UMPDebugGeography) {
  UMPDebugGeographyDisabled = 0,          ///< Disable geography debugging.
  UMPDebugGeographyEEA = 1,               ///< Geography appears as in EEA for debug devices.
  UMPDebugGeographyRegulatedUSState = 3,  ///< Geography appears as in a regulated US State.
  UMPDebugGeographyOther = 4,  ///< Geography appears as in a region with no regulation in force.
  UMPDebugGeographyNotEEA
  __attribute__((deprecated("Deprecated. Use UMPDebugGeographyOther."))) = 2,  ///< Deprecated.
} NS_SWIFT_NAME(DebugGeography);

/// Overrides settings for debugging or testing.
NS_SWIFT_NAME(DebugSettings)
@interface UMPDebugSettings : NSObject <NSCopying>

/// Array of device identifier strings. Debug features are enabled for devices with these
/// identifiers. Debug features are always enabled for simulators.
@property(nonatomic, copy, nullable) NSArray<NSString *> *testDeviceIdentifiers;

/// Debug geography.
@property(nonatomic) UMPDebugGeography geography;

@end
