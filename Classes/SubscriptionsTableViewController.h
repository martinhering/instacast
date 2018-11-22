//
//  SubscriptionsTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 28.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubscriptionsTableViewController : UITableViewController

+ (SubscriptionsTableViewController*) subscriptionsController;

- (void) showEpisodeListForFeed:(CDFeed*)feed animated:(BOOL)animated;
@end
