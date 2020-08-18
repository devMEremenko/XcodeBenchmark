#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MagicalImportFunctions.h"
#import "NSAttributeDescription+MagicalDataImport.h"
#import "NSEntityDescription+MagicalDataImport.h"
#import "NSNumber+MagicalDataImport.h"
#import "NSObject+MagicalDataImport.h"
#import "NSRelationshipDescription+MagicalDataImport.h"
#import "NSString+MagicalDataImport.h"
#import "NSManagedObject+MagicalAggregation.h"
#import "NSManagedObject+MagicalDataImport.h"
#import "NSManagedObject+MagicalFinders.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObject+MagicalRequests.h"
#import "NSManagedObjectContext+MagicalChainSave.h"
#import "NSManagedObjectContext+MagicalObserving.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalSaves.h"
#import "NSManagedObjectContext+MagicalThreading.h"
#import "NSManagedObjectModel+MagicalRecord.h"
#import "NSPersistentStore+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Actions.h"
#import "MagicalRecord+ErrorHandling.h"
#import "MagicalRecord+iCloud.h"
#import "MagicalRecord+Options.h"
#import "MagicalRecord+Setup.h"
#import "MagicalRecord+ShorthandMethods.h"
#import "MagicalRecordDeprecationMacros.h"
#import "MagicalRecordInternal.h"
#import "MagicalRecordLogging.h"
#import "MagicalRecordXcode7CompatibilityMacros.h"
#import "MagicalRecord.h"

FOUNDATION_EXPORT double MagicalRecordVersionNumber;
FOUNDATION_EXPORT const unsigned char MagicalRecordVersionString[];

