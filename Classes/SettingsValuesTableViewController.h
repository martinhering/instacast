//
//  FeedSettingsValuesTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 20.02.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    kSettingTypeString = 0,
    kSettingTypeBool,
    kSettingTypeInteger,
    kSettingTypeDouble,
};
typedef NSInteger SettingValueType;

@class CDFeed;

@interface SettingsValuesTableViewController : UITableViewController

+ (SettingsValuesTableViewController*) tableViewController;

@property (nonatomic, strong) CDFeed* feed;
@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) SettingValueType valueType;
@property (nonatomic, strong) NSArray* titles;
@property (nonatomic, strong) NSArray* values;
@property (nonatomic, strong) NSString* footerText;

@end
