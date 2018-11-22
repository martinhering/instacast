//
//  EpisodesTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 29.12.10.
//  Copyright 2010 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EpisodesTableViewController.h"

@class CDFeed;
@class PullToRefreshView;

@interface FeedEpisodesTableViewController : EpisodesTableViewController

+ (FeedEpisodesTableViewController*) episodesControllerWithFeed:(CDFeed*)feed;

@property (nonatomic, strong) CDFeed* feed;
@property (nonatomic, strong) NSString* searchTerm;

- (void) reloadData;
@end
