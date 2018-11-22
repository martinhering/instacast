//
//  BookmarksTableViewController.h
//  Instacast
//
//  Created by Martin Hering on 22.03.12.
//  Copyright (c) 2012 Vemedio. All rights reserved.
//


@interface BookmarksTableViewController : UITableViewController

+ (id) bookmarksController;

@property (nonatomic, strong) NSString* parentHash;

@property (nonatomic, copy) void (^didDeleteRows)(NSArray* rows);
@property (nonatomic, copy) void (^didDeleteLastRow)();

- (void) reload;
@end
