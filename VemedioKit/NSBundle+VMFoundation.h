//
//  NSBundle+VMFoundation.h
//  VMFoundation
//
//  Created by Martin Hering on 11/07/13.
//  Copyright (c) 2013 Vemedio. All rights reserved.
//

#import <Foundation/Foundation.h>

#define VM_SYSTEM_VERSION_OS_X_10_9 0xA0900

@interface NSBundle (VMFoundation)

+ (NSString*) appVersion;
- (NSString*) appVersion;

+ (NSString*) buildVersion;
- (NSString*) buildVersion;

+ (NSInteger) systemVersion;
+ (NSString*) systemVersionString;

+ (NSString*) macAddress;
+ (NSString*) deviceId;
+ (NSString*) deviceName;
+ (NSString*) platform;

+ (NSString*) pathToLogsDirectory;

@end
