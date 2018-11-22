//
//  DirectoryFeedViewController.h
//  Instacast
//
//  Created by Martin Hering on 17.01.11.
//  Copyright 2011 Vemedio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DirectoryFeedViewController : UIViewController <UIWebViewDelegate> {

}

+ (DirectoryFeedViewController*) directoryFeedViewController;

@property (nonatomic, strong) NSURL* feedURL;
@property (nonatomic, strong) NSURL* itunesURL;
@property (nonatomic) BOOL shouldPopBackToList;
@property (nonatomic) BOOL canBeCanceled;

@property (nonatomic, assign) BOOL processAlternateFeeds;

@property (copy) void (^didLoadFeed)(BOOL success, NSError* error);

- (void) startLoading;
@end
