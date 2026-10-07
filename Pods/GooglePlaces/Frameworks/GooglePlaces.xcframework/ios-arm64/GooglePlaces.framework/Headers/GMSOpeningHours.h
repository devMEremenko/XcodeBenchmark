//
//  GMSOpeningHours.h
//  Google Places SDK for iOS
//
//  Copyright 2018 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//

#import <Foundation/Foundation.h>
#import "GMSPlaceSpecialDay.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * \defgroup OpenNowStatus GMSOpenNowStatus
 * @{
 */

/** Describes the current open status of a place. */
typedef NS_ENUM(NSInteger, GMSOpenNowStatus) {
  /** The place is open now. */
  GMSOpenNowStatusYes,

  /** The place is not open now. */
  GMSOpenNowStatusNo,

  /** Whether the place is open now is unknown. */
  GMSOpenNowStatusUnknown,
};

/**@}*/

/**
 * \defgroup PlaceHoursType GMSPlaceHoursType
 * @{
 */

/**
 * Identifies the type of secondary opening hours.
 *
 * |GMSPlaceHoursType| is only set for secondary opening hours (i.e. opening hours
 * returned from |GMSPlace| secondaryOpeningHours).
 * Place hours types described here:
 * https://developers.google.com/maps/documentation/places/web-service/details#PlaceOpeningHours-type
 */
typedef NS_ENUM(NSInteger, GMSPlaceHoursType) {
  GMSPlaceHoursTypeAccess,
  GMSPlaceHoursTypeBreakfast,
  GMSPlaceHoursTypeBrunch,
  GMSPlaceHoursTypeLunch,
  GMSPlaceHoursTypeDinner,
  GMSPlaceHoursTypeSeniorHours,
  GMSPlaceHoursTypePickup,
  GMSPlaceHoursTypeTakeout,
  GMSPlaceHoursTypeDelivery,
  GMSPlaceHoursTypeKitchen,
  GMSPlaceHoursTypeOnlineServiceHours,
  GMSPlaceHoursTypeDriveThrough,
  GMSPlaceHoursTypeHappyHour,
  GMSPlaceHoursTypeUnknown
};

/**@}*/

/**
 * \defgroup DayOfWeek GMSDayOfWeek
 * @{
 */

/**
 * The fields represent individual days of the week. Matches NSDateComponents.weekday index.
 * Refer to https://developer.apple.com/documentation/foundation/nsdatecomponents/1410442-weekday
 */
typedef NS_ENUM(NSUInteger, GMSDayOfWeek) {
  GMSDayOfWeekSunday = 1,
  GMSDayOfWeekMonday = 2,
  GMSDayOfWeekTuesday = 3,
  GMSDayOfWeekWednesday = 4,
  GMSDayOfWeekThursday = 5,
  GMSDayOfWeekFriday = 6,
  GMSDayOfWeekSaturday = 7,
};

/**@}*/

/** A class representing time in hours and minutes in a 24hr clock. */
@interface GMSTime : NSObject

/** The hour representation of time in a day. (Range is between 0-23). */
@property(nonatomic, readonly, assign) NSUInteger hour;

/** The minute representation of time in a 1 hr period. (Range is between 0-59). */
@property(nonatomic, readonly, assign) NSUInteger minute;

@end

/** A class representing a open/close event in |GMSPeriod|. */
@interface GMSEvent : NSObject

/** Day of week the associated with the event. */
@property(nonatomic, readonly, assign) GMSDayOfWeek day;

/** The representation of time of the event in 24hr clock. */
@property(nonatomic, readonly, strong) GMSTime *time;

@end

/**
 * A class representing a period of time where the place is operating for a |GMSPlace|.
 * It contains an open |GMSEvent| and an optional close |GMSEvent|. The close event will be nil
 * if the period is open 24hrs.
 */
@interface GMSPeriod : NSObject

/**
 * The open event of this period.
 * Each |GMSPeriod| is guaranteed to have an open event.
 * If the period is representing open 24hrs, it will only have the openEvent with time as "0000".
 */
@property(nonatomic, readonly, strong) GMSEvent *openEvent;

/** The close event of this period. Can be nil if period is open 24hrs. */
@property(nullable, nonatomic, readonly, strong) GMSEvent *closeEvent;

@end

/** A class to handle storing and accessing opening hours information for |GMSPlace|. */
@interface GMSOpeningHours : NSObject

/**
 * Contains all |GMSPeriod|s of open and close events for the week.
 *
 * Note: Multiple periods can be associated with a day (eg. Monday 7am - Monday 2pm,
 *                                                          Monday 5pm - Monday 10pm).
 *
 *       Periods may also span multiple days (eg Friday 7pm - Saturday 2am).
 */
@property(nullable, nonatomic, readonly, strong) NSArray<GMSPeriod *> *periods;

/**
 * Contains localized strings of the daily opening hours for the week.
 *
 * Note: The order of the text depends on the language and may begin on Monday or Sunday.
 *       Do not use the GMSDayOfWeek enum to index into the array.
 */
@property(nullable, nonatomic, readonly, strong) NSArray<NSString *> *weekdayText;

/**
 * Returns the |GMSPlaceHoursType| of the opening hours.
 */
@property(nonatomic, readonly) GMSPlaceHoursType hoursType;

/**
 * Returns a list of |GMSPlaceSpecialDay| entries, corresponding to the next
 * seven days which may have opening hours that differ from the normal operating hours.
 */
@property(nonatomic, copy, readonly, nullable) NSArray<GMSPlaceSpecialDay *> *specialDays;
@end

NS_ASSUME_NONNULL_END
