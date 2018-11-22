//
//  DirectorySearchViewController.h
//  Instacast
//
//  Created by Martin Hering on 17.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DirectorySearchViewController : UITableViewController <UISearchBarDelegate> {

}

+ (DirectorySearchViewController*) directorySearchViewController;

@property (nonatomic, strong) NSArray* feeds;
@property (nonatomic, strong) UIBarButtonItem* sidebarMenuItem;
@end
