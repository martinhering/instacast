//
//  FeedSettingsViewController.h
//  Instacast
//
//  Created by Martin Hering on 17.02.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDFeed;

@interface FeedSettingsViewController : UITableViewController

+ (FeedSettingsViewController*) feedSettingsViewControllerWithFeed:(CDFeed*)feed;

@end
